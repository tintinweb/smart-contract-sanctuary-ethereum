// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/*

    TODO: banner

*/

import {ERC721} from "@metalabel/solmate/src/tokens/ERC721.sol";
import {Owned} from "@metalabel/solmate/src/auth/Owned.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {IERC721} from "@openzeppelin/contracts/interfaces/IERC721.sol";

/// @notice Contract that can compute tokenURI values for a given token ID.
interface IMetadataResolver {
    function resolve(address _contract, uint256 _id)
        external
        view
        returns (string memory);
}

/// @notice Data stored for each token series
struct SeriesConfig {
    string metadataBaseURI;
    uint32 variationCount;
    IMetadataResolver metadataResolver;
}

contract PublicMint is ERC721, Owned {
    // ---
    // errors
    // ---

    /// @notice Minting is not allowed currently
    error MintingPaused();

    /// @notice External mint from an invalid msg.sender
    error UnallowedExternalMinter();

    // ---
    // events
    // ---

    /// @notice A token series was configured
    event SeriesConfigSet(
        uint16 indexed seriesId,
        string metadataBaseURI,
        uint32 variationCount,
        IMetadataResolver metadataResolver
    );

    /// @notice An address was added or removed as an allowed minter for a
    /// series.
    event SeriesAllowedMinterSet(
        uint16 indexed seriesId,
        address indexed minter,
        bool isAllowed
    );

    /// @notice The contract owner updated the current active mint.
    event ActiveMintSet(uint16 indexed seriesId, uint64 mintingPausesAt);

    // ---
    // storage
    // ---

    /// @notice The token series actively being minted from this contract.
    /// External minting contracts may mint from any series.
    uint16 public currentMintingSeries = 0;

    /// @notice Timestamp after which minting will be paused. External minting
    /// contracts can mint at any time.
    uint64 public mintingPausesAt = 0;

    /// @notice Total number of minted tokens.
    uint256 public totalSupply;

    /// @notice The URI for the collection-level metadata, only set during
    /// deployment. Checked by OpenSea.
    string public contractURI;

    /// @notice The token series configurations.
    mapping(uint16 => SeriesConfig) public seriesConfigs;

    /// @notice Addresses that are allowed to mint a specific token series.
    mapping(uint16 => mapping(address => bool)) public seriesAllowedMinters;

    /// @notice The address of the ASSEMBLY 001 NFT contract
    IERC721 public immutable assemblyNFT;

    /// @notice Flag to indicate if an address has claimed an NFT with their
    /// ASSEMBLY NFT already
    mapping(address => bool) public assemblyNFTClaimed;

    // ---
    // constructor
    // ---

    constructor(
        string memory _contractURI,
        address _contractOwner,
        IERC721 _assemblyNFT,
        SeriesConfig[] memory _initialSeries
    )
        ERC721("Metalabel Public Mint", "METALABEL-PM")
        Owned(_contractOwner == address(0) ? msg.sender : _contractOwner)
    {
        contractURI = _contractURI;
        assemblyNFT = _assemblyNFT;

        address[] memory emptyMinters = new address[](0);
        for (uint16 i = 0; i < _initialSeries.length; i++) {
            setSeriesConfig(i, _initialSeries[i], emptyMinters);
        }
    }

    // ---
    // Owner functionality
    // ---

    /// @notice Set the active minting series and cutoff time. Only callable by owner.
    function setActiveMint(uint16 _seriesId, uint64 _mintingPausesAt)
        external
        onlyOwner
    {
        currentMintingSeries = _seriesId;
        mintingPausesAt = _mintingPausesAt;
        emit ActiveMintSet(_seriesId, _mintingPausesAt);
    }

    /// @notice Set the configuration for a specific token series. Only callable by owner.
    function setSeriesConfig(
        uint16 _seriesId,
        SeriesConfig memory _config,
        address[] memory _allowedMinters
    ) public onlyOwner {
        seriesConfigs[_seriesId] = _config;

        emit SeriesConfigSet(
            _seriesId,
            _config.metadataBaseURI,
            _config.variationCount,
            _config.metadataResolver
        );

        setSeriesAllowedMinters(_seriesId, _allowedMinters, true);
    }

    /// @notice Set the allowed minters for a specific token series. Only callable by owner.
    function setSeriesAllowedMinters(
        uint16 _seriesId,
        address[] memory _allowedMinters,
        bool isAllowed
    ) public onlyOwner {
        for (uint256 i = 0; i < _allowedMinters.length; i++) {
            seriesAllowedMinters[_seriesId][_allowedMinters[i]] = isAllowed;
            emit SeriesAllowedMinterSet(
                _seriesId,
                _allowedMinters[i],
                isAllowed
            );
        }
    }

    /// @notice Mint a token in a specific series with a prandom seed at any
    /// time, even if minting is currently paused. Only callable by owner.
    function ownerMint(address to, uint16 seriesId)
        external
        onlyOwner
        returns (uint256)
    {
        return _mintToSeries(to, seriesId);
    }

    /// @notice Mint a token in a specific series with a custom seed at any time,
    /// even if minting is currently paused. Only callable by owner.
    function ownerMint(
        address to,
        uint16 seriesId,
        uint48 seed
    ) external onlyOwner returns (uint256) {
        uint256 tokenId = ++totalSupply;
        _mint(to, tokenId, seriesId, seed);
        return tokenId;
    }

    // ---
    // external minter functionality
    // ---

    /// @notice Mint from an external allowed minting contract with a prandom
    /// seed.
    function externalMint(address to, uint16 seriesId)
        external
        returns (uint256)
    {
        if (!seriesAllowedMinters[seriesId][msg.sender]) {
            revert UnallowedExternalMinter();
        }

        return _mintToSeries(to, seriesId);
    }

    /// @notice Mint from an external allowed minting contract with a custom
    /// seed.
    function externalMint(
        address to,
        uint16 seriesId,
        uint48 seed
    ) external returns (uint256) {
        if (!seriesAllowedMinters[seriesId][msg.sender]) {
            revert UnallowedExternalMinter();
        }

        uint256 tokenId = ++totalSupply;
        _mint(to, tokenId, seriesId, seed);
        return tokenId;
    }

    // ---
    // public functionality
    // ---

    /// @notice Mint a new token from the currenetly active series.
    /// @param to The address to mint the token to.
    /// @param mintBonusNFT If true, and "to" has an OG ASSEMBLY NFT they
    /// haven't yet used to mint an NFT from the ASSEMBLY series, then a bonus
    /// NFT will also be minted.
    function mint(address to, bool mintBonusNFT) external returns (uint256) {
        if (block.timestamp >= mintingPausesAt) revert MintingPaused();

        // If the caller wants to also their bonus NFT for assembly, check to
        // see if they own the OG assembly NFT and havent yet claimed
        if (
            mintBonusNFT &&
            assemblyNFT != IERC721(address(0)) &&
            assemblyNFT.balanceOf(to) > 0 &&
            !assemblyNFTClaimed[to]
        ) {
            _mintToSeries(to, 3);
            assemblyNFTClaimed[to] = true;
        }

        return _mintToSeries(to, currentMintingSeries);
    }

    /// @notice Internal mint logic
    function _mintToSeries(address to, uint16 seriesId)
        internal
        returns (uint256)
    {
        uint256 tokenId = ++totalSupply;
        uint48 seed = uint48(
            uint256(
                keccak256(
                    abi.encodePacked(
                        tokenId,
                        seriesId,
                        msg.sender,
                        blockhash(block.number - 1)
                    )
                )
            )
        );
        _mint(to, tokenId, seriesId, seed);
        return tokenId;
    }

    // ---
    // metadata logic
    // ---

    /// @notice Return the metadata URI for a token.
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        SeriesConfig memory config = seriesConfigs[
            _tokenData[tokenId].seriesId
        ];

        // use an external resolver if set
        if (config.metadataResolver != IMetadataResolver(address(0))) {
            return config.metadataResolver.resolve(address(this), tokenId);
        }

        // determine the variation psuedorandomly as a function of token seed
        uint256 variation = uint256(
            keccak256(abi.encodePacked(_tokenData[tokenId].seed))
        ) % config.variationCount;

        // otherwise concatenate the base URI and the token ID
        return
            string(
                abi.encodePacked(
                    config.metadataBaseURI,
                    "variation-",
                    Strings.toString(variation),
                    ".json"
                )
            );
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Data stored per-token, fits into a single storage word
struct TokenData {
    address owner;
    uint32 truncatedTimestamp;
    uint16 seriesId;
    uint48 seed;
}

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event TokenDataSet(uint256 indexed id, uint16 indexed seriesId, uint48 indexed seed);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => TokenData) internal _tokenData;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _tokenData[id].owner) != address(0), "NOT_MINTED");
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
        address owner = _tokenData[id].owner;

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
        require(from == _tokenData[id].owner, "WRONG_FROM");

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

        _tokenData[id].owner = to;

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
        return _mint(to, id, 0, 0);
    }

    function _mint(address to, uint256 id, uint16 seriesId, uint48 seed) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_tokenData[id].owner == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _tokenData[id] = TokenData({
            owner: to,
            truncatedTimestamp: uint32(block.timestamp / 10),
            seriesId: seriesId,
            seed: seed
        });

        emit Transfer(address(0), to, id);
        emit TokenDataSet(id, seriesId, seed);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _tokenData[id].owner;

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _tokenData[id];

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

    /*//////////////////////////////////////////////////////////////
                    METALABEL ADDED FUNCTIONALITY
    //////////////////////////////////////////////////////////////*/

    function getTokenData(uint256 id) external view virtual returns (TokenData memory) {
        TokenData memory data = _tokenData[id];
        require(data.owner != address(0), "NOT_MINTED");
        return data;
    }

    function getApproximateTokenMintTimestamp(uint256 id) external view virtual returns (uint256) {
        TokenData memory data = _tokenData[id];
        require(data.owner != address(0), "NOT_MINTED");
        return uint256(data.truncatedTimestamp) * 10;
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

    function setOwner(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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