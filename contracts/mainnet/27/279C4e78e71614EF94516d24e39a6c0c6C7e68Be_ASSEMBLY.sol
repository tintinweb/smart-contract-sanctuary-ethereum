// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/*

███╗   ███╗███████╗████████╗ █████╗ ██╗      █████╗ ██████╗ ███████╗██╗
████╗ ████║██╔════╝╚══██╔══╝██╔══██╗██║     ██╔══██╗██╔══██╗██╔════╝██║
██╔████╔██║█████╗     ██║   ███████║██║     ███████║██████╔╝█████╗  ██║
██║╚██╔╝██║██╔══╝     ██║   ██╔══██║██║     ██╔══██║██╔══██╗██╔══╝  ██║
██║ ╚═╝ ██║███████╗   ██║   ██║  ██║███████╗██║  ██║██████╔╝███████╗███████╗
╚═╝     ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚══════╝

 █████╗ ███████╗███████╗███████╗███╗   ███╗██████╗ ██╗  ██╗   ██╗     ██████╗  ██████╗  ██╗
██╔══██╗██╔════╝██╔════╝██╔════╝████╗ ████║██╔══██╗██║  ╚██╗ ██╔╝    ██╔═████╗██╔═████╗███║
███████║███████╗███████╗█████╗  ██╔████╔██║██████╔╝██║   ╚████╔╝     ██║██╔██║██║██╔██║╚██║
██╔══██║╚════██║╚════██║██╔══╝  ██║╚██╔╝██║██╔══██╗██║    ╚██╔╝      ████╔╝██║████╔╝██║ ██║
██║  ██║███████║███████║███████╗██║ ╚═╝ ██║██████╔╝███████╗██║       ╚██████╔╝╚██████╔╝ ██║
╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝╚═╝     ╚═╝╚═════╝ ╚══════╝╚═╝        ╚═════╝  ╚═════╝  ╚═╝


Metalabel — ASSEMBLY 001 Member

Holders of the ASSEMBLY 001 membership NFT are graduates of Metalabel's
application-only laboratory program exploring creativity in multiplayer mode.
The only way to hold this NFT is to be part of a cultural collective or creative
project that completed ASSEMBLY 001.

Deployed by Metalabel with 💖 as a permanent application on the Ethereum blockchain.

https://assembly.metalabel.xyz/

Anna Bulbrook
Lauren Dorman
Rob Kalin
Austin Robey
Yancey Strickler
Brandon Valosek
Ilya Yudanov

*/

import {ERC721} from "solmate/src/tokens/ERC721.sol";
import {Owned} from "solmate/src/auth/Owned.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

interface IMetadataResolver {
    function resolve(address _contract, uint256 _id)
        external
        view
        returns (string memory);
}

contract ASSEMBLY is ERC721, Owned {
    // ---
    // events
    // ---

    /// @notice The external metadata resolver was set.
    event MetadataResolverSet(IMetadataResolver resolver);

    /// @notice The contract metadata URI was set.
    event ContractURISet(string uri);

    /// @notice The token metadata base URI was set.
    event TokenMetadataBaseURISet(string uri);

    /// @notice The transfer lock was permanently removed.
    event TokenTransferLockBurned();

    /// @notice The owner transfer control was permanently removed.
    event OwnerTransferControlBurned();

    // ---
    // storage
    // ---

    /// @notice If set, metadata is resolved by an external contract.
    IMetadataResolver public metadataResolver;

    /// @notice Total number of minted tokens.
    uint256 public totalSupply;

    /// @notice The URI for the collection-level metadata, checked by OpenSea.
    string public contractURI;

    /// @notice the URI prefix for token-level metadata.
    string public tokenMetadataBaseURI;

    /// @notice If true, normal token transfers are enabled. Once set, it cannot be unset.
    bool public isTransferLockBurned;

    /// @notice If true, contract owner no longer has unilateral transfer
    /// privileges. Once set, it cannot be unset.
    bool public isOwnerTransferControlBurned;

    // ---
    // constructor
    // ---

    constructor(string memory _contractURI, string memory _tokenURI)
        ERC721("Metalabel ASSEMBLY 001", "ASSEMBLY-001")
        Owned(msg.sender)
    {
        contractURI = _contractURI;
        tokenMetadataBaseURI = _tokenURI;
    }

    // ---
    // Owner functionality
    // ---

    /// @notice Mint NFTs to an array of recipients. Only callable by owner.
    function batchMint(address[] calldata recipients) external onlyOwner {
        // copy to memory to avoid incrementing the storage variable
        uint256 tokenId = totalSupply;

        for (uint256 i = 0; i < recipients.length; i++) {
            _mint(recipients[i], ++tokenId);
        }

        // update total supply to be last issued token ID
        totalSupply = tokenId;
    }

    /// @notice Set the metadata resolver. Only callable by owner.
    function setMetadataResolver(IMetadataResolver resolver)
        external
        onlyOwner
    {
        metadataResolver = resolver;
        emit MetadataResolverSet(resolver);
    }

    /// @notice Update the contract metadata URI. Only callable by owner.
    function setContractURI(string calldata uri) external onlyOwner {
        contractURI = uri;
        emit ContractURISet(uri);
    }

    //// @notice Update the token metadata base URI. Only callable by owner.
    function setTokenURI(string calldata uri) external onlyOwner {
        tokenMetadataBaseURI = uri;
        emit TokenMetadataBaseURISet(uri);
    }

    /// @notice Permanently remove the transfer lock. Only callable by owner.
    function burnTransferLock() external onlyOwner {
        isTransferLockBurned = true;
        emit TokenTransferLockBurned();
    }

    /// @notice Permanently remove the owner transfer control. Only callable by owner.
    function burnOwnerTransferControl() external onlyOwner {
        isOwnerTransferControlBurned = true;
        emit OwnerTransferControlBurned();
    }

    /// @notice Transfer a token to a new owner. Only callable by owner. Not
    /// callable if the owner transfer control fuse has been burned.
    function adminTransfer(uint256 tokenId, address to) external onlyOwner {
        require(
            !isOwnerTransferControlBurned,
            "OWNER_TRANSFER_CONTROL_DISABLED"
        );

        address currentOwner = _ownerOf[tokenId];
        require(currentOwner != address(0), "NOT_MINTED");

        // transfer logic, copy-pasted from underlying erc721 implementation.
        // unchecked math since overflow not feasible.
        _ownerOf[tokenId] = to;
        unchecked {
            _balanceOf[currentOwner]--;
            _balanceOf[to]++;
        }
        emit Transfer(currentOwner, to, tokenId);
    }

    // ---
    // transfer functionality
    // ---

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual override {
        require(isTransferLockBurned, "TRANSFER_LOCKED");

        ERC721.transferFrom(from, to, id);
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
        // default to using an external resolver if we override it
        if (metadataResolver != IMetadataResolver(address(0))) {
            return metadataResolver.resolve(address(this), tokenId);
        }

        // otherwise concatenate the base URI and the token ID
        return
            string(
                abi.encodePacked(
                    tokenMetadataBaseURI,
                    Strings.toString(tokenId),
                    ".json"
                )
            );
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
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