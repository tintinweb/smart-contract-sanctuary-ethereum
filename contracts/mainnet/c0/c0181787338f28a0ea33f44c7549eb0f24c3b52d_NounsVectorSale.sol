// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC721} from "solmate/tokens/ERC721.sol";
import "solmate/auth/Owned.sol";

import "./NounsVector.sol";

contract NounsVectorSale is Owned {
    // Token contract.
    NounsVector public nounsVector;

    // Sale state.
    bool public salePaused = true;

    // Max number of each artwork.
    uint256 public constant MAX_ARTWORK_SUPPLY = 150;

    // Number of free mints available.
    uint256 public constant MAX_FREE_MINTS = 25;

    // Number of artworks.
    uint256 public constant NUM_ARTWORKS = 8;

    // Price per mint.
    uint256 public constant MINT_PRICE = 0.15 ether;

    // Number of tokens minted for free per artwork.
    // Represented as 40 bits, 5 per artwork. Right most bits are for artwork 0.
    uint256 private freeMintCount;

    // Record of addresses that have minted a free token.
    // Represented as 8 bits, 1 per artwork. Right most bits are for artwork 0.
    mapping(address => uint256) private freeMinters;

    constructor(NounsVector _nounsVector) Owned(msg.sender) {
        nounsVector = _nounsVector;
    }

    // ADMIN //

    /**
     * @notice Set sale paused or not.
     * @param _salePaused The new sale pause status.
     */
    function setSalePaused(bool _salePaused) external onlyOwner {
        salePaused = _salePaused;
    }

    /**
     * @notice Withdraw Ether from the contract.
     * @param _recipient The receive of the funds.
     */
    function withdraw(address _recipient) external onlyOwner {
        (bool sent, ) = payable(_recipient).call{
            value: address(this).balance
        }("");
        require(sent, "FAILED TO SEND ETH");
    }

    // EXTERNAL //

    /**
     * @notice Mint a paid token of an artwork.
     * @param _artwork The artwork to mint.
     */
    function mint(uint256 _artwork) external payable {
        require(msg.value >= MINT_PRICE, "NOT ENOUGH ETH");

        _mint(_artwork);
    }

    /**
     * @notice Mint a free token of an artwork.
     * @dev We do bit manipulation on the free mint count. To increment the count,
     *      we grab the bits at the slot for the artwork. Then we zero out the slot
     *      using an AND. Then we replace the bits at the slot with an incremented
     *      value using an OR.
     * @param _artwork The artwork to mint.
     */
    function mintFree(uint256 _artwork) external {
        uint256 bits = freeMintCount; // cache value
        uint256 numFreeMinted = _getNumFreeMintedFromBits(bits, _artwork);
        require(numFreeMinted < MAX_FREE_MINTS, "MAX FREE MINT REACHED");
        uint256 newNumFreeMintedMask = (numFreeMinted + 1) * (2 ** (_artwork * 5));

        // increment count for artwork
        freeMintCount = (bits & _getEmptyMaskForArtwork(_artwork)) | newNumFreeMintedMask;

        uint256 mintStatus = freeMinters[msg.sender]; // cache value
        uint256 mask = 2 ** _artwork;
        require(mintStatus & mask == 0, "ALREADY FREE MINTED");

        // record free mint for caller
        freeMinters[msg.sender] = mintStatus ^ mask;

        _mint(_artwork);
    }

    /**
     * @notice Return the number of tokens minted for free for an artwork.
     * @param _artwork The artwork to check.
     * @return Number of free tokens that have been minted for an artwork.
     */
    function getNumFreeMinted(uint256 _artwork) public view returns (uint256) {
        return _getNumFreeMintedFromBits(freeMintCount, _artwork);
    }

    /**
     * @notice Return whether an account has minted a specific artwork for free.
     * @param _account Account to check.
     * @param _artwork The artwork to check.
     * @return Boolean representing if an account minted a free token or not.
     */
    function hasMintedFree(
        address _account,
        uint256 _artwork
    ) public view returns (bool) {
        return freeMinters[_account] & (2 ** _artwork) > 0;
    }

    // INTERNAL //

    /**
     * Calls the mint function of the token contract.
     *
     * @param _artwork Artwork of token to mint.
     */
    function _mint(uint256 _artwork) internal {
        require(!salePaused, "SALE PAUSED");
        require(_artwork < NUM_ARTWORKS, "INVALID ARTWORK");
        require(nounsVector.artworkSupply(_artwork) < MAX_ARTWORK_SUPPLY, "SOLD OUT");

        nounsVector.mint(msg.sender, _artwork);
    }

    /**
     * @notice Extracts from bits the number of free minted tokens for an artwork.
     * @dev Uses the bit representation of free mint counts.
     * @param _bits Bits representing the count of free mints.
     * @param _artwork The artwork to check.
     * @return Number of free tokens that have been minted for an artwork.
     */
    function _getNumFreeMintedFromBits(
        uint256 _bits,
        uint256 _artwork
    ) internal pure returns (uint256) {
        uint256 mask = (2 ** 5 - 1) * (2 ** (_artwork * 5));
        return (_bits & mask) / (2 ** (_artwork * 5));
    }

    /**
     * @notice Return the bit mask to zero out the bits allotted for an artwork's free mint count.
     * @dev    0 0b11111_11111_11111_11111_11111_11111_11111_00000
     *         1 0b11111_11111_11111_11111_11111_11111_00000_11111
     *         2 0b11111_11111_11111_11111_11111_00000_11111_11111
     *         3 0b11111_11111_11111_11111_00000_11111_11111_11111
     *         4 0b11111_11111_11111_00000_11111_11111_11111_11111
     *         5 0b11111_11111_00000_11111_11111_11111_11111_11111
     *         6 0b11111_00000_11111_11111_11111_11111_11111_11111
     *         7 0b00000_11111_11111_11111_11111_11111_11111_11111
     * @return Number representing bit mask.
     */
    function _getEmptyMaskForArtwork(uint256 _artwork) internal pure returns (uint256) {
        if (_artwork == 0) {
            return 1099511627744;
        } else if (_artwork == 1) {
            return 1099511626783;
        } else if (_artwork == 2) {
            return 1099511596031;
        } else if (_artwork == 3) {
            return 1099510611967;
        } else if (_artwork == 4) {
            return 1099479121919;
        } else if (_artwork == 5) {
            return 1098471440383;
        } else if (_artwork == 6) {
            return 1066225631231;
        } else {
            return 34359738367;
        }
    }

    // FALLBACKS //

    fallback() external payable {}

    receive() external payable {}
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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "solmate/auth/Owned.sol";
import {ERC721} from "solmate/tokens/ERC721.sol";

import "./lib/Base64.sol";

contract NounsVector is ERC721, Owned, AccessControl {
    // Artwork and edition # that a token corresponds to.
    struct TokenInfo {
        uint8 artwork;
        uint8 edition;
    }

    // Role that can change the image base URI.
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // Role that can mint tokens.
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    // Image base URI.
    string public imageBaseURI;

    // Total supply.
    uint256 public totalSupply;

    // Supply per artwork.
    mapping(uint256 => uint256) private artworkSupplies;

    // Artwork and edition info for a token.
    mapping(uint256 => TokenInfo) private tokenInfos;

    constructor(string memory _imageBaseURI) ERC721("Nouns x Vector", "NOUNV") Owned(msg.sender) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);

        imageBaseURI = _imageBaseURI;
    }

    // ADMIN //

    /**
     * @notice Change the base URI for the image.
     */
    function setImageBaseURI(string calldata _imageBaseURI) public onlyRole(ADMIN_ROLE) {
        imageBaseURI = _imageBaseURI;
    }

    // PUBLIC //

    /**
     * @notice Require that the sender is the minter.
     * @param _id The token ID.
     * @return string The token metadata encoded in base64.
     */
    function tokenURI(uint256 _id) public view override returns (string memory) {
        require(_exists(_id), "ERC721Metadata: URI query for nonexistent token");

        TokenInfo memory tokenInfo = tokenInfos[_id];

        string memory base64JSON = Base64.encode(
            bytes(
                string.concat(
                    '{',
                        '"name": "', _getTokenName(tokenInfo.artwork, tokenInfo.edition), '", ',
                        '"description": "', _getArtworkDescription(tokenInfo.artwork), '", ',
                        '"image": "', imageBaseURI, Strings.toString(tokenInfo.artwork), '", ',
                        '"attributes": ', _getArtworkAttributes(tokenInfo.artwork, tokenInfo.edition),
                    '}'
                )
            )
        );

        return string.concat('data:application/json;base64,', base64JSON);
    }

    // EXTERNAL //

    /**
     * @notice Mints a token of an artwork to an account. Only the privileged
     *         minter role may mint tokens.
     * @param _to The recipient of the minting.
     * @param _artwork The artwork to mint.
     */
    function mint(
        address _to,
        uint256 _artwork
    ) external onlyRole(MINTER_ROLE) {
        _safeMint(_to, totalSupply);

        unchecked {
            ++artworkSupplies[_artwork]; // 1-indexed
        }

        tokenInfos[totalSupply] = TokenInfo(uint8(_artwork), uint8(artworkSupplies[_artwork]));

        unchecked {
            ++totalSupply;
        }
    }

    /**
     * @notice Returns the number of tokens minted of an artwork.
     * @param _artwork The artwork in question.
     * @return Number of editions.
     */
    function artworkSupply(uint256 _artwork) external view returns (uint256) {
        return artworkSupplies[_artwork];
    }

    // INTERNAL //

    /**
     * @notice Returns the artist of the artwork.
     * @param _artwork The artwork in question.
     * @return Name of the artist.
     */
    function _getArtworkArtist(uint256 _artwork) internal pure returns (string memory) {
        if (_artwork == 0) {
            return "Adam Ho";
        } else if (_artwork == 1) {
            return "Elijah Anderson";
        } else if (_artwork == 2) {
            return "Eric Hu";
        } else if (_artwork == 3) {
            return "Haruko Hayakawa";
        } else if (_artwork == 4) {
            return "Lulu Lin";
        } else if (_artwork == 5) {
            return "Moon Collective";
        } else if (_artwork == 6) {
            return "Shawna X";
        } else {
            return "Yasly";
        }
    }

    /**
     * @notice Returns the name of the token for metadata.
     * @param _artwork The artwork in question.
     * @param _edition The edition number.
     * @return Name of the token.
     */
    function _getTokenName(uint256 _artwork, uint256 _edition) internal pure returns (string memory) {
        return string.concat(_getArtworkArtist(_artwork), " #", Strings.toString(_edition), " ", unicode"—", " Nouns x Vector");
    }

    /**
     * @notice Returns the description of the artwork.
     * @param _artwork The artwork in question.
     * @return Description of the artwork.
     */
    function _getArtworkDescription(uint256 _artwork) internal pure returns (string memory) {
        if (_artwork == 0) {
            return "Adam Ho is a designer and artist with a strong focus on branding, interaction design, and art direction. He is based in Queens, New York. He has worked with clients such as Medium, Airbnb, Square, Dropbox, Postmates, and Nike.";
        } else if (_artwork == 1) {
            return "Elijah Anderson is a multidisciplinary artist who has collaborated and worked with a range of brands and publications including New York Mag, Popeye mag, Adidas, Sneakers n Stuff, and Bookworks. He currently lives in Brooklyn, New York.";
        } else if (_artwork == 2) {
            return "Eric Hu is an independent creative director and typographer. Through the visual identity work of his eponymous design studio, his art direction for Mold Magazine, previous tenures leading design at Nike and SSENSE, Hu has been influential in shaping the visual language of some of the most lasting cultural, commercial, and institutional voices of the past decade.";
        } else if (_artwork == 3) {
            return "Haruko Hayakawa is a CG Artist and Creative Director based in Brooklyn, New York. Her work focuses on her Japanese-American culture, materiality and form. She has worked with The New York Times, Bon Appetit, Fly by Jing, Panera Bread and SKYY Vodka.";
        } else if (_artwork == 4) {
            return "Lulu Lin is an interdisciplinary designer, she has garnered the most public interest for her illustrations. Her drawings has been described as subverting human forms in surprising and engrossing ways, often lumpy and fleshy, strike the viewer as playful, surreal, and sometimes unsettling.";
        } else if (_artwork == 5) {
            return "Moon Collective is an Asian American clothing and design studio based in the Bay Area and Honolulu. We draw inspiration from minimalism, a peaceful journey, funny memories and psychedelic folklore. We produce designs we love throughout the four seasons and dedicate our time developing our in-house brand, Moon strives to build community through our work and our friendship.";
        } else if (_artwork == 6) {
            return "Shawna X an artist based in New York City, known for her vibrant and surreal image-making on projects about identity, motherhood, and community. Her recent collaborations include public art takeovers with large-scale murals in Brazil, and NYC LIRR station debuting in fall of 2022.";
        } else {
            return string.concat(
                "YASLY is Danny Jones, a 3D Designer living in San Francisco, California exploring the space between what is real and what is not",
                unicode"—",
                "3D helps him understand and see in a new way. Danny's constantly taking notice of the imperfections in the world and how those translate into the work he creates."
            );
        }
    }

    /**
     * @notice Returns the attributes of the artwork.
     * @param _artwork The artwork in question.
     * @param _edition The edition of the artwork.
     * @return Attributes describing the token.
     */
    function _getArtworkAttributes(uint256 _artwork, uint256 _edition) internal pure returns (string memory) {
        return string.concat(
            '[',
                '{"trait_type": "artist", "value": "', _getArtworkArtist(_artwork), '"},',
                '{"trait_type": "edition", "value": "', Strings.toString(_edition), '"},',
                '{"trait_type": "license", "value": "CC BY-NC-SA 4.0"}',
            ']'
        );
    }

    /**
     * @notice Returns whether a token has been minted or not.
     * @param _id The token ID.
     * @return Whether it exists or not.
     */
    function _exists(uint256 _id) internal view returns (bool) {
        return _ownerOf[_id] != address(0);
    }

    function supportsInterface(bytes4 interfaceId) public pure override(ERC721, AccessControl) returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f || // ERC165 Interface ID for ERC721Metadata
            interfaceId == type(IAccessControl).interfaceId;
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
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

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
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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