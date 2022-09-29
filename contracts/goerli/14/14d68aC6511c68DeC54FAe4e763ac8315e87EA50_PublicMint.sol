// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/*

    TODO: banner

*/

import {ERC721} from "@metalabel/solmate/src/tokens/ERC721.sol";
import {Owned} from "@metalabel/solmate/src/auth/Owned.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

interface IMetadataResolver {
    function resolve(address _contract, uint256 _id)
        external
        view
        returns (string memory);
}

/// @notice Data stored for each token group
struct GroupConfig {
    string metadataBaseURI;
    uint32 variationCount;
    IMetadataResolver metadataResolver;
}

contract PublicMint is ERC721, Owned {
    // ---
    // events
    // ---

    /// @notice The external metadata resolver was set.
    event GroupConfigSet(
        uint16 indexed groupId,
        string metadataBaseURI,
        uint32 variationCount,
        address metadataResolver
    );

    /// @notice An address was added or removed as a group authorized minter.
    event GroupAuthorizedMinterSet(
        uint16 indexed groupId,
        address indexed minter,
        bool isAuthorized
    );

    // ---
    // storage
    // ---

    /// @notice Total number of minted tokens.
    uint256 public totalSupply;

    /// @notice The URI for the collection-level metadata, only set during
    /// deployment. Checked by OpenSea.
    string public contractURI;

    /// @notice The token group configurations.
    mapping(uint16 => GroupConfig) public groupConfigs;

    /// @notice Addresses that are authorized to mint a specific token group.
    mapping(uint16 => mapping(address => bool)) public groupAuthorizedMinters;

    // ---
    // constructor
    // ---

    constructor(string memory _contractURI, address _contractOwner)
        ERC721("Metalabel Public Mint", "METALABEL-PM")
        Owned(_contractOwner == address(0) ? msg.sender : _contractOwner)
    {
        contractURI = _contractURI;
    }

    // ---
    // Owner functionality
    // ---

    /// @notice Set the configuration for a specific token group. Only callable by owner.
    function setGroupConfig(
        uint16 _groupId,
        string memory _metadataBaseURI,
        uint32 _variationCount,
        IMetadataResolver _metadataResolver,
        address[] memory _authorizedMinters
    ) external onlyOwner {
        groupConfigs[_groupId] = GroupConfig({
            metadataBaseURI: _metadataBaseURI,
            variationCount: _variationCount,
            metadataResolver: _metadataResolver
        });

        emit GroupConfigSet(
            _groupId,
            _metadataBaseURI,
            _variationCount,
            address(_metadataResolver)
        );

        setGroupAuthorizedMinters(_groupId, _authorizedMinters, true);
    }

    /// @notice Set the authorized minters for a specific token group. Only callable by owner.
    function setGroupAuthorizedMinters(
        uint16 _groupId,
        address[] memory _authorizedMinters,
        bool isAuthorized
    ) public onlyOwner {
        for (uint256 i = 0; i < _authorizedMinters.length; i++) {
            groupAuthorizedMinters[_groupId][
                _authorizedMinters[i]
            ] = isAuthorized;
            emit GroupAuthorizedMinterSet(
                _groupId,
                _authorizedMinters[i],
                isAuthorized
            );
        }
    }

    // ---
    // public functionality
    // ---

    /// @notice Mint a new token
    function mint(address to) external returns (uint256) {
        return _mintToGroup(to, 0);
    }

    /// @notice Internal mint logic
    function _mintToGroup(address to, uint16 groupId) internal returns (uint256) {
        uint256 tokenId = ++totalSupply;
        uint48 seed = uint48(
            uint256(
                keccak256(
                    abi.encodePacked(
                        tokenId,
                        groupId,
                        msg.sender,
                        blockhash(block.number - 1)
                    )
                )
            )
        );
        _mint(to, tokenId, groupId, seed);
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
        GroupConfig memory config = groupConfigs[_tokenData[tokenId].groupId];

        // use an external resolver if set
        if (config.metadataResolver != IMetadataResolver(address(0))) {
            return config.metadataResolver.resolve(address(this), tokenId);
        }

        // determine the variation psuedorandomly as a function of token seed
        uint256 variation = uint256(keccak256(abi.encodePacked(tokenId))) %
            config.variationCount;

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
    uint16 groupId;
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

    event TokenDataSet(uint256 indexed id, uint16 indexed groupId, uint48 indexed seed);

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

    function _mint(address to, uint256 id, uint16 groupId, uint48 seed) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_tokenData[id].owner == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _tokenData[id] = TokenData({
            owner: to,
            truncatedTimestamp: uint32(block.timestamp / 10),
            groupId: groupId,
            seed: seed
        });

        emit Transfer(address(0), to, id);
        emit TokenDataSet(id, groupId, seed);
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