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
    function toString(int256 value) internal pure returns (string memory str) {
        if (value >= 0) return toString(uint256(value));

        unchecked {
            str = toString(uint256(-value));

            /// @solidity memory-safe-assembly
            assembly {
                // Note: This is only safe because we over-allocate memory
                // and write the string from right to left in toString(uint256),
                // and thus can be sure that sub(str, 1) is an unused memory location.

                let length := mload(str) // Load the string length.
                // Put the - character at the start of the string contents.
                mstore(str, 45) // 45 is the ASCII code for the - character.
                str := sub(str, 1) // Move back the string pointer by a byte.
                mstore(str, add(length, 1)) // Update the string length.
            }
        }
    }

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

import {Owned} from "solmate/auth/Owned.sol";
import {ERC721} from "solmate/tokens/ERC721.sol";
import {LibString} from "solmate/utils/LibString.sol";

import "@/contracts/utils/ColormapDataConstants.sol";
import {IColormapRegistry} from "@/contracts/interfaces/IColormapRegistry.sol";
import {Base64} from "@/contracts/utils/Base64.sol";

contract CheckTheChain is ERC721, Owned {
    // -------------------------------------------------------------------------
    // Constants
    // -------------------------------------------------------------------------

    /// @notice The minting period.
    uint256 constant MINT_LENGTH = 5 days;

    /// @notice Mint fee.
    uint256 constant MINT_FEE = 0.0048 ether;

    /// @notice Salt used to compute the seed in {CheckTheChain-tokenURI}.
    bytes32 constant SALT = bytes32("CheckTheChain");

    /// @notice The owner address.
    address constant OWNER_ADDRESS = 0xA85572Cd96f1643458f17340b6f0D6549Af482F5;

    // -------------------------------------------------------------------------
    // Storage
    // -------------------------------------------------------------------------

    /// @notice The start of the minting period.
    uint256 immutable mintStart;

    /// @notice The colormap registry.
    IColormapRegistry immutable colormapRegistry;

    /// @notice The total number of tokens.
    uint256 public totalSupply;

    // -------------------------------------------------------------------------
    // Constructor + Mint
    // -------------------------------------------------------------------------

    /// @notice Deploys the contract.
    constructor() ERC721("CheckTheChain", "CTC") Owned(OWNER_ADDRESS) {
        mintStart = block.timestamp;

        colormapRegistry = IColormapRegistry(
            0x0000000012883D1da628e31c0FE52e35DcF95D50
        );

        // Mint 25 to the owner.
        for (uint256 i = 1; i < 26; ) {
            _mint(OWNER_ADDRESS, i);
            unchecked {
                ++i;
            }
        }
        totalSupply = 25;
    }

    /// @notice Mints a token to the sender.
    function mint() external payable {
        unchecked {
            if (block.timestamp > mintStart + MINT_LENGTH) {
                revert("MINTING_NOT_STARTED");
            }
            if (msg.value < MINT_FEE) {
                revert("INSUFFICIENT_FEE");
            }

            _mint(msg.sender, ++totalSupply);
        }
    }

    /// @notice Withdraw contract funds to the contract owner `owner`.
    function withdraw() external onlyOwner {
        (bool success, ) = payable(owner).call{value: address(this).balance}(
            ""
        );
        require(success);
    }

    // -------------------------------------------------------------------------
    // ERC721Metadata
    // -------------------------------------------------------------------------

    /// @inheritdoc ERC721
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_ownerOf[_tokenId] != address(0), "NOT_MINTED");

        uint256 seed = uint256(keccak256(abi.encodePacked(_tokenId, SALT)));

        (
            bytes32 colormapHash,
            string memory colormapName,
            bool isDark
        ) = _getColormap(seed % 18);

        return
            string.concat(
                "data:application/json;base64,",
                Base64.encode(
                    abi.encodePacked(
                        '{"name":"Check the Chain #',
                        LibString.toString(_tokenId),
                        '","description":"On-chain checks, inspired by VV.",',
                        '"image_data":"data:image/svg+xml;base64,',
                        Base64.encode(
                            abi.encodePacked(
                                _renderSvg(seed, colormapHash, isDark)
                            )
                        ),
                        '","attributes":[{"trait_type":"Colormap","value":"',
                        colormapName,
                        '"}]}'
                    )
                )
            );
    }

    // -------------------------------------------------------------------------
    // Helper Functions
    // -------------------------------------------------------------------------

    function _renderSvg(
        uint256 _seed,
        bytes32 _colormapHash,
        bool _isDark
    ) internal view returns (string memory) {
        string memory svgContents;

        uint256 i;
        while (_seed != 0 && i < 80) {
            // Position along the colormap.
            uint8 position = uint8(1 << (_seed & 7));
            string memory color = colormapRegistry.getValueAsHexString(
                _colormapHash,
                position
            );

            unchecked {
                {
                    svgContents = string.concat(
                        svgContents,
                        '<g transform="translate(',
                        LibString.toString(uint256(196 + (i & 7) * 40)),
                        " ",
                        LibString.toString(uint256(160 + (i >> 3) * 40)),
                        ')"><rect x="-20" y="-20" width="40" height="40" stroke="#',
                        _isDark ? "E6E6E6" : "191919",
                        '" fill="#',
                        _isDark ? "F5F5F5" : "111111",
                        '"/><circle r="4" fill="#',
                        color,
                        '"/><circle cx="6" r="4" fill="#',
                        color,
                        '"/><circle cx="-6" r="4" fill="#',
                        color
                    );
                }
                {
                    svgContents = string.concat(
                        svgContents,
                        '"/><circle cy="-6" r="4" fill="#',
                        color,
                        '"/><circle cy="6" r="4" fill="#',
                        color,
                        '"/><circle cx="4.243" cy="4.243" r="4" fill="#',
                        color,
                        '"/><circle cx="4.243" cy="-4.243" r="4" fill="#',
                        color,
                        '"/><circle cx="-4.243" cy="4.243" r="4" fill="#',
                        color,
                        '"/><circle cx="-4.243" cy="-4.243" r="4" fill="#',
                        color,
                        '"/><path d="m-.6 3.856 4.56-6.844c.566-.846-.75-1.724-1.316-.878L-1.38 2.177-2.75.809c-.718-.722-1.837.396-1.117 1.116l2.17 2.15a.784.784 0 0 0 .879-.001.767.767 0 0 0 .218-.218Z" fill="#',
                        _isDark ? "F5F5F5" : "111111",
                        '"/></g>'
                    );
                }
                _seed >>= 3;
                ++i;
            }
        }

        return
            string.concat(
                '<svg width="680" height="680" viewBox="0 0 680 680" fill="none" xmlns="http://www.w3.org/2000/svg">',
                '<path xmlns="http://www.w3.org/2000/svg" d="M680 0H0V680H680V0Z" fill="',
                _isDark ? "white" : "black",
                '"/>',
                svgContents,
                "</svg>"
            );
    }

    function _getColormap(uint256 _index)
        internal
        pure
        returns (
            bytes32,
            string memory,
            bool
        )
    {
        if (_index < 9) {
            if (_index < 4) {
                if (_index < 2) {
                    if (_index == 0) {
                        return (
                            GNUPLOT_COLORMAP_HASH,
                            GNUPLOT_NAME,
                            GNUPLOT_IS_DARK
                        );
                    }
                    return (CMRMAP_COLORMAP_HASH, CMRMAP_NAME, CMRMAP_IS_DARK);
                }
                if (_index == 2) {
                    return (WISTIA_COLORMAP_HASH, WISTIA_NAME, WISTIA_IS_DARK);
                }
                return (AUTUMN_COLORMAP_HASH, AUTUMN_NAME, AUTUMN_IS_DARK);
            }
            if (_index < 6) {
                if (_index == 4) {
                    return (BINARY_COLORMAP_HASH, BINARY_NAME, BINARY_IS_DARK);
                }
                return (BONE_COLORMAP_HASH, BONE_NAME, BONE_IS_DARK);
            }
            if (_index < 7) {
                if (_index == 6) {
                    return (COOL_COLORMAP_HASH, COOL_NAME, COOL_IS_DARK);
                }
                return (COPPER_COLORMAP_HASH, COPPER_NAME, COPPER_IS_DARK);
            }
            return (
                GIST_RAINBOW_COLORMAP_HASH,
                GIST_RAINBOW_NAME,
                GIST_RAINBOW_IS_DARK
            );
        }
        if (_index < 13) {
            if (_index < 11) {
                if (_index == 9) {
                    return (
                        GIST_STERN_COLORMAP_HASH,
                        GIST_STERN_NAME,
                        GIST_STERN_IS_DARK
                    );
                }
                return (GRAY_COLORMAP_HASH, GRAY_NAME, GRAY_IS_DARK);
            }
            if (_index == 11) {
                return (HOT_COLORMAP_HASH, HOT_NAME, HOT_IS_DARK);
            }
            return (HSV_COLORMAP_HASH, HSV_NAME, HSV_IS_DARK);
        }
        if (_index < 15) {
            if (_index == 13) {
                return (JET_COLORMAP_HASH, JET_NAME, JET_IS_DARK);
            }
            return (SPRING_COLORMAP_HASH, SPRING_NAME, SPRING_IS_DARK);
        }
        if (_index < 17) {
            if (_index == 15) {
                return (SUMMER_COLORMAP_HASH, SUMMER_NAME, SUMMER_IS_DARK);
            }
            return (TERRAIN_COLORMAP_HASH, TERRAIN_NAME, TERRAIN_IS_DARK);
        }
        return (WINTER_COLORMAP_HASH, WINTER_NAME, WINTER_IS_DARK);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IPaletteGenerator} from "@/contracts/interfaces/IPaletteGenerator.sol";

/// @title The interface for the colormap registry.
/// @author fiveoutofnine
/// @dev A colormap may be defined in 2 ways: (1) via segment data and (2) via a
/// ``palette generator.''
///     1. via segment data
///     2. or via a palette generator ({IPaletteGenerator}).
/// Segment data contains 1 `uint256` each for red, green, and blue describing
/// their intensity values along the colormap. Each `uint256` contains 24-bit
/// words bitpacked together with the following structure (bits are
/// right-indexed):
///     | Bits      | Meaning                                              |
///     | --------- | ---------------------------------------------------- |
///     | `23 - 16` | Position in the colormap the segment begins from     |
///     | `15 - 08` | Intensity of R, G, or B the previous segment ends at |
///     | `07 - 00` | Intensity of R, G, or B the next segment starts at   |
/// Given some position, the output will be computed via linear interpolations
/// on the segment data for R, G, and B. A maximum of 10 of these segments fit
/// within 256 bits, so up to 9 segments can be defined. If you need more
/// granularity or a nonlinear palette function, you may implement
/// {IPaletteGenerator} and define a colormap with that.
interface IColormapRegistry {
    // -------------------------------------------------------------------------
    // Errors
    // -------------------------------------------------------------------------

    /// @notice Emitted when a colormap already exists.
    /// @param _colormapHash Hash of the colormap's definition.
    error ColormapAlreadyExists(bytes32 _colormapHash);

    /// @notice Emitted when a colormap does not exist.
    /// @param _colormapHash Hash of the colormap's definition.
    error ColormapDoesNotExist(bytes32 _colormapHash);

    /// @notice Emitted when a segment data used to define a colormap does not
    /// follow the representation outlined in {IColormapRegistry}.
    /// @param _segmentData Segment data for 1 of R, G, or B. See
    /// {IColormapRegistry} for its representation.
    error SegmentDataInvalid(uint256 _segmentData);

    // -------------------------------------------------------------------------
    // Structs
    // -------------------------------------------------------------------------

    /// @notice Segment data that defines a colormap when read via piece-wise
    /// linear interpolation.
    /// @dev Each param contains 24-bit words, so each one may contain at most
    /// 9 (24*10 - 1) segments. See {IColormapRegistry} for how the segment data
    /// should be structured.
    /// @param r Segment data for red's color value along the colormap.
    /// @param g Segment data for green's color value along the colormap.
    /// @param b Segment data for blue's color value along the colormap.
    struct SegmentData {
        uint256 r;
        uint256 g;
        uint256 b;
    }

    // -------------------------------------------------------------------------
    // Events
    // -------------------------------------------------------------------------

    /// @notice Emitted when a colormap is registered via a palette generator
    /// function.
    /// @param _hash Hash of `_paletteGenerator`.
    /// @param _paletteGenerator Instance of {IPaletteGenerator} for the
    /// colormap.
    event RegisterColormap(bytes32 _hash, IPaletteGenerator _paletteGenerator);

    /// @notice Emitted when a colormap is registered via segment data.
    /// @param _hash Hash of `_segmentData`.
    /// @param _segmentData Segment data defining the colormap.
    event RegisterColormap(bytes32 _hash, SegmentData _segmentData);

    // -------------------------------------------------------------------------
    // Storage
    // -------------------------------------------------------------------------

    /// @param _colormapHash Hash of the colormap's definition (segment data).
    /// @return uint256 Segment data for red's color value along the colormap.
    /// @return uint256 Segment data for green's color value along the colormap.
    /// @return uint256 Segment data for blue's color value along the colormap.
    function segments(bytes32 _colormapHash)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    /// @param _colormapHash Hash of the colormap's definition (palette
    /// generator).
    /// @return IPaletteGenerator Instance of {IPaletteGenerator} for the
    /// colormap.
    function paletteGenerators(bytes32 _colormapHash)
        external
        view
        returns (IPaletteGenerator);

    // -------------------------------------------------------------------------
    // Actions
    // -------------------------------------------------------------------------

    /// @notice Register a colormap with a palette generator.
    /// @param _paletteGenerator Instance of {IPaletteGenerator} for the
    /// colormap.
    function register(IPaletteGenerator _paletteGenerator) external;

    /// @notice Register a colormap with segment data that will be read via
    /// piece-wise linear interpolation.
    /// @dev See {IColormapRegistry} for how the segment data should be
    /// structured.
    /// @param _segmentData Segment data defining the colormap.
    function register(SegmentData memory _segmentData) external;

    // -------------------------------------------------------------------------
    // View
    // -------------------------------------------------------------------------

    /// @notice Get the red, green, and blue color values of a color in a
    /// colormap at some position.
    /// @dev Each color value will be returned as a 18 decimal fixed-point
    /// number in [0, 1]. Note that the function *will not* revert if
    /// `_position` is an invalid input (i.e. greater than 1e18). This
    /// responsibility is left to the implementation of {IPaletteGenerator}s.
    /// @param _colormapHash Hash of the colormap's definition.
    /// @param _position 18 decimal fixed-point number in [0, 1] representing
    /// the position in the colormap (i.e. 0 being min, and 1 being max).
    /// @return uint256 Intensity of red in that color at the position
    /// `_position`.
    /// @return uint256 Intensity of green in that color at the position
    /// `_position`.
    /// @return uint256 Intensity of blue in that color at the position
    /// `_position`.
    function getValue(bytes32 _colormapHash, uint256 _position)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    /// @notice Get the red, green, and blue color values of a color in a
    /// colormap at some position.
    /// @dev Each color value will be returned as a `uint8` number in [0, 255].
    /// @param _colormapHash Hash of the colormap's definition.
    /// @param _position Position in the colormap (i.e. 0 being min, and 255
    /// being max).
    /// @return uint8 Intensity of red in that color at the position
    /// `_position`.
    /// @return uint8 Intensity of green in that color at the position
    /// `_position`.
    /// @return uint8 Intensity of blue in that color at the position
    /// `_position`.
    function getValueAsUint8(bytes32 _colormapHash, uint8 _position)
        external
        view
        returns (
            uint8,
            uint8,
            uint8
        );

    /// @notice Get the hexstring for a color in a colormap at some position.
    /// @param _colormapHash Hash of the colormap's definition.
    /// @param _position Position in the colormap (i.e. 0 being min, and 255
    /// being max).
    /// @return string Hexstring excluding ``#'' (e.g. `007CFF`) of the color
    /// at the position `_position`.
    function getValueAsHexString(bytes32 _colormapHash, uint8 _position)
        external
        view
        returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title The interface for a palette generator.
/// @author fiveoutofnine
/// @dev `IPaletteGenerator` contains generator functions for a color's red,
/// green, and blue color values. Each of these functions is intended to take in
/// a 18 decimal fixed-point number in [0, 1] representing the position in the
/// colormap and return the corresponding 18 decimal fixed-point number in
/// [0, 1] representing the value of each respective color.
interface IPaletteGenerator {
    // -------------------------------------------------------------------------
    // Errors
    // -------------------------------------------------------------------------

    /// @notice Reverts if the position is not a valid input.
    /// @dev The position is not a valid input if it is greater than 1e18.
    /// @param _position Position in the colormap.
    error InvalidPosition(uint256 _position);

    // -------------------------------------------------------------------------
    // Generators
    // -------------------------------------------------------------------------

    /// @notice Computes the intensity of red of the palette at some position.
    /// @dev The function should revert if `_position` is not a valid input
    /// (i.e. greater than 1e18). Also, the return value for all inputs must be
    /// a 18 decimal.
    /// @param _position Position in the colormap.
    /// @return uint256 Intensity of red in that color at the position
    /// `_position`.
    function r(uint256 _position) external pure returns (uint256);

    /// @notice Computes the intensity of green of the palette at some position.
    /// @dev The function should revert if `_position` is not a valid input
    /// (i.e. greater than 1e18). Also, the return value for all inputs must be
    /// a 18 decimal.
    /// @param _position Position in the colormap.
    /// @return uint256 Intensity of green in that color at the position
    /// `_position`.
    function g(uint256 _position) external pure returns (uint256);

    /// @notice Computes the intensity of blue of the palette at some position.
    /// @dev The function should revert if `_position` is not a valid input
    /// (i.e. greater than 1e18). Also, the return value for all inputs must be
    /// a 18 decimal.
    /// @param _position Position in the colormap.
    /// @return uint256 Intensity of blue in that color at the position
    /// `_position`.
    function b(uint256 _position) external pure returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz012345678"
        "9+/";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";
        string memory table = TABLE;
        uint256 encodedLength = ((data.length + 2) / 3) << 2;
        string memory result = new string(encodedLength + 0x20);

        assembly {
            mstore(result, encodedLength)
            let tablePtr := add(table, 1)
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))
            let resultPtr := add(result, 0x20)

            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)
                mstore(
                    resultPtr,
                    shl(0xF8, mload(add(tablePtr, and(shr(0x12, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(0xF8, mload(add(tablePtr, and(shr(0xC, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(0xF8, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
                mstore(
                    resultPtr,
                    shl(0xF8, mload(add(tablePtr, and(input, 0x3F))))
                )
                resultPtr := add(resultPtr, 1)
            }
            switch mod(mload(data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(0xF0, 0x3D3D))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(0xF8, 0x3D))
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

bytes32 constant GNUPLOT_COLORMAP_HASH = 0xfd29b65966772202ffdb08f653439b30c849f91409915665d99dbfa5e5dab938;
string constant GNUPLOT_NAME = "gnuplot";
bool constant GNUPLOT_IS_DARK = true;

bytes32 constant CMRMAP_COLORMAP_HASH = 0x850ce48e7291439b1e41d21fc3f75dddd97580a4ff94aa9ebdd2bcbd423ea1e8;
string constant CMRMAP_NAME = "CMRmap";
bool constant CMRMAP_IS_DARK = true;

bytes32 constant WISTIA_COLORMAP_HASH = 0x4f5e8ea8862eff315c110b682ee070b459ba8983a7575c9a9c4c25007039109d;
string constant WISTIA_NAME = "Wistia";
bool constant WISTIA_IS_DARK = false;

bytes32 constant AUTUMN_COLORMAP_HASH = 0xf2e92189cb6903b98d854cd74ece6c3fafdb2d3472828a950633fdaa52e05032;
string constant AUTUMN_NAME = "autumn";
bool constant AUTUMN_IS_DARK = false;

bytes32 constant BINARY_COLORMAP_HASH = 0xa33e6c7c5627ecabfd54c4d85f9bf04815fe89a91379fcf56ccd8177e086db21;
string constant BINARY_NAME = "binary";
bool constant BINARY_IS_DARK = false;

bytes32 constant BONE_COLORMAP_HASH = 0xaa84b30df806b46f859a413cb036bc91466307aec5903fc4635c00a421f25d5c;
string constant BONE_NAME = "bone";
bool constant BONE_IS_DARK = true;

bytes32 constant COOL_COLORMAP_HASH = 0x864a6ee98b9b21ac0291523750d637250405c24a6575e1f75cfbd7209a810ce6;
string constant COOL_NAME = "cool";
bool constant COOL_IS_DARK = false;

bytes32 constant COPPER_COLORMAP_HASH = 0xfd60cd3811f002814944a7d36167b7c9436187a389f2ee476dc883e37dc76bd2;
string constant COPPER_NAME = "copper";
bool constant COPPER_IS_DARK = true;

bytes32 constant GIST_RAINBOW_COLORMAP_HASH = 0xa8309447f8bd3b5e5e88a0abc05080b7682e4456c388b8636d45f5abb2ad2587;
string constant GIST_RAINBOW_NAME = "gist_rainbow";
bool constant GIST_RAINBOW_IS_DARK = false;

bytes32 constant GIST_STERN_COLORMAP_HASH = 0x3be719b0c342797212c4cb33fde865ed9cbe486eb67176265bc0869b54dee925;
string constant GIST_STERN_NAME = "gist_stern";
bool constant GIST_STERN_IS_DARK = true;

bytes32 constant GRAY_COLORMAP_HASH = 0xca0da6b6309ed2117508207d68a59a18ccaf54ba9aa329f4f60a77481fcf2027;
string constant GRAY_NAME = "gray";
bool constant GRAY_IS_DARK = true;

bytes32 constant HOT_COLORMAP_HASH = 0x5ccb29670bb9de0e3911d8e47bde627b0e3640e49c3d6a88d51ff699160dfbe1;
string constant HOT_NAME = "hot";
bool constant HOT_IS_DARK = true;

bytes32 constant HSV_COLORMAP_HASH = 0x3de8f27f386dab3dbab473f3cc16870a717fe5692b4f6a45003d175c559dfcba;
string constant HSV_NAME = "hsv";
bool constant HSV_IS_DARK = false;

bytes32 constant JET_COLORMAP_HASH = 0x026736ef8439ebcf8e7b8006bf8cb7482ced84d71b900407a9ed63e1b7bfe234;
string constant JET_NAME = "jet";
bool constant JET_IS_DARK = true;

bytes32 constant SPRING_COLORMAP_HASH = 0xc1806ea961848ac00c1f20aa0611529da522a7bd125a3036fe4641b07ee5c61c;
string constant SPRING_NAME = "spring";
bool constant SPRING_IS_DARK = false;

bytes32 constant SUMMER_COLORMAP_HASH = 0x87970b686eb726750ec792d49da173387a567764d691294d764e53439359c436;
string constant SUMMER_NAME = "summer";
bool constant SUMMER_IS_DARK = false;

bytes32 constant TERRAIN_COLORMAP_HASH = 0xaa6277ab923279cf59d78b9b5b7fb5089c90802c353489571fca3c138056fb1b;
string constant TERRAIN_NAME = "terrain";
bool constant TERRAIN_IS_DARK = true;

bytes32 constant WINTER_COLORMAP_HASH = 0xdc1cecffc00e2f3196daaf53c27e53e6052a86dc875adb91607824d62469b2bf;
string constant WINTER_NAME = "winter";
bool constant WINTER_IS_DARK = true;