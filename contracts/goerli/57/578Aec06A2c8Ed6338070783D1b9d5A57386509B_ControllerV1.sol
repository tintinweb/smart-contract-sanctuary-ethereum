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

/// @notice Data stored per-token, fits into a single storage word
struct TokenData {
    address owner;
    uint16 sequenceId;
    uint80 data;
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

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

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

    function _mint(address to, uint256 id, uint16 sequenceId, uint80 data) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_tokenData[id].owner == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _tokenData[id] = TokenData({
            owner: to,
            sequenceId: sequenceId,
            data: data
        });

        emit Transfer(address(0), to, id);
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

/// @notice Gas optimized merkle proof verification library.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/MerkleProofLib.sol)
/// @author Modified from Solady (https://github.com/Vectorized/solady/blob/main/src/utils/MerkleProofLib.sol)
library MerkleProofLib {
    function verify(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool isValid) {
        assembly {
            if proof.length {
                // Left shifting by 5 is like multiplying by 32.
                let end := add(proof.offset, shl(5, proof.length))

                // Initialize offset to the offset of the proof in calldata.
                let offset := proof.offset

                // Iterate over proof elements to compute root hash.
                // prettier-ignore
                for {} 1 {} {
                    // Slot where the leaf should be put in scratch space. If
                    // leaf > calldataload(offset): slot 32, otherwise: slot 0.
                    let leafSlot := shl(5, gt(leaf, calldataload(offset)))

                    // Store elements to hash contiguously in scratch space.
                    // The xor puts calldataload(offset) in whichever slot leaf
                    // is not occupying, so 0 if leafSlot is 32, and 32 otherwise.
                    mstore(leafSlot, leaf)
                    mstore(xor(leafSlot, 32), calldataload(offset))

                    // Reuse leaf to store the hash to reduce stack operations.
                    leaf := keccak256(0, 64) // Hash both slots of scratch space.

                    offset := add(offset, 32) // Shift 1 word per cycle.

                    // prettier-ignore
                    if iszero(lt(offset, end)) { break }
                }
            }

            isValid := eq(leaf, root) // The proof is valid if the roots match.
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Read and write to persistent storage at a fraction of the cost.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SSTORE2.sol)
/// @author Modified from 0xSequence (https://github.com/0xSequence/sstore2/blob/master/contracts/SSTORE2.sol)
library SSTORE2 {
    uint256 internal constant DATA_OFFSET = 1; // We skip the first byte as it's a STOP opcode to ensure the contract can't be called.

    /*//////////////////////////////////////////////////////////////
                               WRITE LOGIC
    //////////////////////////////////////////////////////////////*/

    function write(bytes memory data) internal returns (address pointer) {
        // Prefix the bytecode with a STOP opcode to ensure it cannot be called.
        bytes memory runtimeCode = abi.encodePacked(hex"00", data);

        bytes memory creationCode = abi.encodePacked(
            //---------------------------------------------------------------------------------------------------------------//
            // Opcode  | Opcode + Arguments  | Description  | Stack View                                                     //
            //---------------------------------------------------------------------------------------------------------------//
            // 0x60    |  0x600B             | PUSH1 11     | codeOffset                                                     //
            // 0x59    |  0x59               | MSIZE        | 0 codeOffset                                                   //
            // 0x81    |  0x81               | DUP2         | codeOffset 0 codeOffset                                        //
            // 0x38    |  0x38               | CODESIZE     | codeSize codeOffset 0 codeOffset                               //
            // 0x03    |  0x03               | SUB          | (codeSize - codeOffset) 0 codeOffset                           //
            // 0x80    |  0x80               | DUP          | (codeSize - codeOffset) (codeSize - codeOffset) 0 codeOffset   //
            // 0x92    |  0x92               | SWAP3        | codeOffset (codeSize - codeOffset) 0 (codeSize - codeOffset)   //
            // 0x59    |  0x59               | MSIZE        | 0 codeOffset (codeSize - codeOffset) 0 (codeSize - codeOffset) //
            // 0x39    |  0x39               | CODECOPY     | 0 (codeSize - codeOffset)                                      //
            // 0xf3    |  0xf3               | RETURN       |                                                                //
            //---------------------------------------------------------------------------------------------------------------//
            hex"60_0B_59_81_38_03_80_92_59_39_F3", // Returns all code in the contract except for the first 11 (0B in hex) bytes.
            runtimeCode // The bytecode we want the contract to have after deployment. Capped at 1 byte less than the code size limit.
        );

        assembly {
            // Deploy a new contract with the generated creation code.
            // We start 32 bytes into the code to avoid copying the byte length.
            pointer := create(0, add(creationCode, 32), mload(creationCode))
        }

        require(pointer != address(0), "DEPLOYMENT_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                               READ LOGIC
    //////////////////////////////////////////////////////////////*/

    function read(address pointer) internal view returns (bytes memory) {
        return readBytecode(pointer, DATA_OFFSET, pointer.code.length - DATA_OFFSET);
    }

    function read(address pointer, uint256 start) internal view returns (bytes memory) {
        start += DATA_OFFSET;

        return readBytecode(pointer, start, pointer.code.length - start);
    }

    function read(
        address pointer,
        uint256 start,
        uint256 end
    ) internal view returns (bytes memory) {
        start += DATA_OFFSET;
        end += DATA_OFFSET;

        require(pointer.code.length >= end, "OUT_OF_BOUNDS");

        return readBytecode(pointer, start, end - start);
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function readBytecode(
        address pointer,
        uint256 start,
        uint256 size
    ) private view returns (bytes memory data) {
        assembly {
            // Get a pointer to some free memory.
            data := mload(0x40)

            // Update the free memory pointer to prevent overriding our data.
            // We use and(x, not(31)) as a cheaper equivalent to sub(x, mod(x, 32)).
            // Adding 31 to size and running the result through the logic above ensures
            // the memory pointer remains word-aligned, following the Solidity convention.
            mstore(0x40, add(data, and(add(add(size, 32), 31), not(31))))

            // Store the size of the data in the first 32 byte chunk of free memory.
            mstore(data, size)

            // Copy the code into memory right after the 32 bytes we used to store the size.
            extcodecopy(pointer, add(data, 32), start, size)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
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
pragma solidity 0.8.17;

/*

███╗   ███╗███████╗████████╗ █████╗ ██╗      █████╗ ██████╗ ███████╗██╗
████╗ ████║██╔════╝╚══██╔══╝██╔══██╗██║     ██╔══██╗██╔══██╗██╔════╝██║
██╔████╔██║█████╗     ██║   ███████║██║     ███████║██████╔╝█████╗  ██║
██║╚██╔╝██║██╔══╝     ██║   ██╔══██║██║     ██╔══██║██╔══██╗██╔══╝  ██║
██║ ╚═╝ ██║███████╗   ██║   ██║  ██║███████╗██║  ██║██████╔╝███████╗███████╗
╚═╝     ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚══════╝


Deployed by Metalabel with 💖 as a permanent application on the Ethereum blockchain.

Metalabel is a growing universe of tools, knowledge, and resources for
metalabels and cultural collectives.

Our purpose is to establish the metalabel as key infrastructure for creative
collectives and to inspire a new culture of creative collaboration and mutual
support.

OUR SQUAD

Anna Bulbrook (Curator)
Austin Robey (Community)
Brandon Valosek (Engineer)
Ilya Yudanov (Designer)
Lauren Dorman (Engineer)
Rob Kalin (Board)
Yancey Strickler (Director)

https://metalabel.xyz

*/

import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {ERC721} from "@metalabel/solmate/src/tokens/ERC721.sol";
import {SSTORE2} from "@metalabel/solmate/src/utils/SSTORE2.sol";
import {INodeRegistry} from "./interfaces/INodeRegistry.sol";
import {IEngine, SequenceData} from "./interfaces/IEngine.sol";
import {ICollection} from "./interfaces/ICollection.sol";
import {Resource, AccessControlData} from "./Resource.sol";

/// @notice Immutable data stored per-collection.
/// @dev This is stored via SSTORE2 to save gas.
struct ImmutableCollectionData {
    string name;
    string symbol;
    string contractURI;
}

/// @notice Collections are ERC721 contracts that contain records.
/// - Minting logic, tokenURI, and royalties are delegated to an external engine
///     contract
/// - Sequences are a mapping between an external engine contract and parameters
///     stored in the collection
/// - Multiple sequences can be configured for a single collection, records may
///     be rendered and minted in a variety of different ways
contract Collection is ERC721, Resource, ICollection, IERC2981 {
    // ---
    // Errors
    // ---

    /// @notice The init function was called more than once.
    error AlreadyInitialized();

    /// @notice A record mint attempt was made for a sequence that is currently
    /// sealed.
    error SequenceIsSealed();

    /// @notice A record mint attempt was made for a sequence that has no
    /// remaining supply.
    error SequenceSupplyExhausted();

    /// @notice An invalid sequence config was provided during configuration.
    error InvalidSequenceConfig();

    /// @notice msg.sender during a mint call did not match expected engine
    /// origin.
    error InvalidMintRequest();

    // ---
    // Events
    // ---

    /// @notice A new record was minted.
    /// @dev The underlying ERC721 implementation already emits a Transfer event
    /// on mint, this event announces the sequence the token is minted into and
    /// its immutable token data.
    event RecordCreated(
        uint256 indexed tokenId,
        uint16 indexed sequenceId,
        uint80 data
    );

    /// @notice A sequence has been set or updated.
    event SequenceConfigured(
        uint16 indexed sequenceId,
        SequenceData sequenceData,
        bytes engineData
    );

    /// @notice The owner address of this collection was updated.
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    // ---
    // Storage
    // ---

    /// @notice Total number of records minted in this collection.
    uint256 public totalSupply;

    /// @notice Total number of sequences configured in this collection.
    uint16 public sequenceCount;

    /// @notice Only for marketplace interop, can be set by owner of the control
    /// node.
    address public owner;

    /// @notice The SSTORE2 storage pointer for immutable collection data.
    /// @dev This data is exposed through name, symbol, and contractURI views
    address internal immutableStoragePointer;

    /// @notice Information about each sequence.
    mapping(uint16 => SequenceData) internal sequences;

    // ---
    // Constructor
    // ---

    /// @dev Constructor only called during deployment of the implementation,
    /// all storage should be set up in init function which is called atomically
    /// after clone deployment
    constructor() {
        // Write dummy data to the immutable storage pointer to prevent
        // initialization of the implementation contract.
        immutableStoragePointer = SSTORE2.write(
            abi.encode(
                ImmutableCollectionData({name: "", symbol: "", contractURI: ""})
            )
        );
    }

    // ---
    // Clone init
    // ---

    /// @notice Initialize contract state.
    /// @dev Should be called immediately after deploying the clone in the same
    /// transaction.
    function init(
        address _owner,
        AccessControlData calldata _accessControl,
        string calldata _metadata,
        ImmutableCollectionData calldata _data
    ) external {
        if (immutableStoragePointer != address(0)) revert AlreadyInitialized();
        immutableStoragePointer = SSTORE2.write(abi.encode(_data));

        // Set ERC721 market interop.
        owner = _owner;
        emit OwnershipTransferred(address(0), owner);

        // Assign access control data.
        accessControl = _accessControl;

        // This memberships collection is a resource that can be cataloged -
        // emit the initial metadata value
        emit Broadcast("metadata", _metadata);
    }

    // ---
    // Admin functionality
    // ---

    /// @notice Change the owner address of this collection.
    /// @dev This is only here for market interop, access control is handled via
    /// the control node.
    function setOwner(address _owner) external onlyAuthorized {
        address previousOwner = owner;
        owner = _owner;
        emit OwnershipTransferred(previousOwner, _owner);
    }

    /// @notice Create a new sequence configuration.
    /// @dev The _engineData bytes parameter is arbitrary data that is passed
    /// directly to the engine powering this new sequence.
    function configureSequence(
        SequenceData calldata _sequence,
        bytes calldata _engineData
    ) external onlyAuthorized {
        // The drop this sequence is associated with must be manageable by
        // msg.sender. This is in addition to the onlyAuthorized modifier which
        // asserts msg.sender can manage the control node of the whole
        // collection.
        // msg.sender is either a metalabel admin EOA, or a controller contract
        // that has been authorized to do drops on the drop node.
        if (
            !accessControl.nodeRegistry.isAuthorizedAddressForNode(
                _sequence.dropNodeId,
                msg.sender
            )
        ) {
            revert NotAuthorized();
        }

        // If there is sealedAfter timestamp (i.e timebound sequence), ensure
        // that sealedBefore is strictly less than sealedAfter AND that
        // sealedAfter occurs strictly in the future. If sealedAfter is zero,
        // there is no time limit. We are allowing cases where sealedBefore
        // occurs in the past.
        if (
            _sequence.sealedAfterTimestamp > 0 &&
            (_sequence.sealedBeforeTimestamp >=
                _sequence.sealedAfterTimestamp ||
                _sequence.sealedAfterTimestamp <= block.timestamp)
        ) {
            revert InvalidSequenceConfig();
        }

        // Prevent having a minted count before the sequence starts. This
        // wouldn't break anything, but would cause the indexed "minted" amount
        // from actual mints to differ from the sequence data tracking total
        // supply, which is non-ideal and worth the small gas to check.
        //
        // We're not using a separate struct here for inputs that omits the
        // minted count field, being able to copy from calldata to storage is
        // nice.
        if (_sequence.minted != 0) {
            revert InvalidSequenceConfig();
        }

        // Write sequence data to storage
        uint16 sequenceId = ++sequenceCount;
        sequences[sequenceId] = _sequence;
        emit SequenceConfigured(sequenceId, _sequence, _engineData);

        // Invoke configureSequence on the engine to give it a chance to setup
        // and store any needed info. Doing this after event emitting so that
        // indexers see the sequence first before any engine-side events
        _sequence.engine.configureSequence(sequenceId, _sequence, _engineData);
    }

    // ---
    // Engine functionality
    // ---

    /// @inheritdoc ICollection
    function mintRecord(
        address to,
        uint16 sequenceId,
        uint80 tokenData
    ) external returns (uint256 tokenId) {
        SequenceData storage sequence = sequences[sequenceId];
        _validateSequence(sequence);

        // Mint the record.
        tokenId = ++totalSupply;
        ++sequence.minted;
        _mint(to, tokenId, sequenceId, tokenData);
        emit RecordCreated(tokenId, sequenceId, tokenData);
    }

    /// @inheritdoc ICollection
    function mintRecord(address to, uint16 sequenceId)
        external
        returns (uint256 tokenId)
    {
        SequenceData storage sequence = sequences[sequenceId];
        _validateSequence(sequence);

        // Mint the record.
        tokenId = ++totalSupply;
        uint64 editionNumber = ++sequence.minted;
        _mint(to, tokenId, sequenceId, editionNumber);
        emit RecordCreated(tokenId, sequenceId, editionNumber);
    }

    /// @dev Ensure a given sequence is valid to mint into by the current msg.sender
    function _validateSequence(SequenceData memory sequence) internal view {
        // Ensure that only the engine for this sequence can mint records. Mint
        // transactions termiante on the engine side - the engine then invokes
        // the mint functions on the Collection.
        if (sequence.engine != IEngine(msg.sender)) {
            revert InvalidMintRequest();
        }

        // Ensure that mint is not happening before or after allowed window.
        if (
            block.timestamp < sequence.sealedBeforeTimestamp ||
            (sequence.sealedAfterTimestamp > 0 && // sealed after = 0 => no end
                block.timestamp >= sequence.sealedAfterTimestamp)
        ) {
            revert SequenceIsSealed();
        }

        // Ensure we have remaining supply to mint
        if (sequence.maxSupply > 0 && sequence.minted >= sequence.maxSupply) {
            revert SequenceSupplyExhausted();
        }
    }

    // ---
    // ICollection views
    // ---

    /// @inheritdoc ICollection
    function getSequenceData(uint16 sequenceId)
        external
        view
        override
        returns (SequenceData memory sequence)
    {
        sequence = sequences[sequenceId];
    }

    // ---
    // ERC721 views
    // ---

    /// @notice The collection name.
    function name() public view virtual returns (string memory value) {
        value = _resolveImmutableStorage().name;
    }

    /// @notice The collection symbol.
    function symbol() public view virtual returns (string memory value) {
        value = _resolveImmutableStorage().symbol;
    }

    /// @inheritdoc ERC721
    /// @dev Resolve token URI from the engine powering the sequence.
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory uri)
    {
        IEngine engine = sequences[_tokenData[tokenId].sequenceId].engine;
        uri = engine.getTokenURI(address(this), tokenId);
    }

    /// @notice Get the contract URI.
    function contractURI() public view virtual returns (string memory value) {
        value = _resolveImmutableStorage().contractURI;
    }

    // ---
    // Misc views
    // ---

    /// @inheritdoc ICollection
    function tokenSequenceId(uint256 tokenId)
        external
        view
        returns (uint16 sequenceId)
    {
        sequenceId = _tokenData[tokenId].sequenceId;
    }

    /// @inheritdoc ICollection
    /// @dev Token mint data is either edition number or arbitrary custom data
    /// passed in the by the engine at mint-time.
    function tokenMintData(uint256 tokenId)
        external
        view
        returns (uint80 data)
    {
        data = _tokenData[tokenId].data;
    }

    // ---
    // ERC2981 functionality
    // ---

    /// @inheritdoc IERC2981
    /// @dev Resolve royalty info from the engine powering the sequence.
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        IEngine engine = sequences[_tokenData[tokenId].sequenceId].engine;
        return engine.getRoyaltyInfo(address(this), tokenId, salePrice);
    }

    // ---
    // Introspection
    // ---

    /// @inheritdoc IERC165
    /// @dev ERC165 checks return true for: ERC165, ERC721, and ERC2981.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    // ---
    // Internal views
    // ---

    /// @dev Read name/symbol/contractURI strings via SSTORE2.
    function _resolveImmutableStorage()
        internal
        view
        returns (ImmutableCollectionData memory data)
    {
        data = abi.decode(
            SSTORE2.read(immutableStoragePointer),
            (ImmutableCollectionData)
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/*

███╗   ███╗███████╗████████╗ █████╗ ██╗      █████╗ ██████╗ ███████╗██╗
████╗ ████║██╔════╝╚══██╔══╝██╔══██╗██║     ██╔══██╗██╔══██╗██╔════╝██║
██╔████╔██║█████╗     ██║   ███████║██║     ███████║██████╔╝█████╗  ██║
██║╚██╔╝██║██╔══╝     ██║   ██╔══██║██║     ██╔══██║██╔══██╗██╔══╝  ██║
██║ ╚═╝ ██║███████╗   ██║   ██║  ██║███████╗██║  ██║██████╔╝███████╗███████╗
╚═╝     ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚══════╝


Deployed by Metalabel with 💖 as a permanent application on the Ethereum blockchain.

Metalabel is a growing universe of tools, knowledge, and resources for
metalabels and cultural collectives.

Our purpose is to establish the metalabel as key infrastructure for creative
collectives and to inspire a new culture of creative collaboration and mutual
support.

OUR SQUAD

Anna Bulbrook (Curator)
Austin Robey (Community)
Brandon Valosek (Engineer)
Ilya Yudanov (Designer)
Lauren Dorman (Engineer)
Rob Kalin (Board)
Yancey Strickler (Director)

https://metalabel.xyz

*/

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {INodeRegistry} from "./interfaces/INodeRegistry.sol";
import {Collection, ImmutableCollectionData} from "./Collection.sol";
import {AccessControlData} from "./Resource.sol";

/// @notice Configuration data required when deploying a new collection.
struct CreateCollectionConfig {
    string name;
    string symbol;
    string contractURI;
    address owner;
    uint64 controlNodeId;
    string metadata;
}

/// @notice A factory that deploys record collections.
contract CollectionFactory {
    // ---
    // Errors
    // ---

    /// @notice An unauthorized address attempted to create a collection.
    error NotAuthorized();

    // ---
    // Events
    // ---

    /// @notice A new collection was deployed
    event CollectionCreated(address indexed collection);

    // ---
    // Storage
    // ---

    /// @notice Reference to the collection implementation that will be cloned.
    Collection public immutable implementation;

    /// @notice Reference to the node registry of the protocol.
    INodeRegistry public immutable nodeRegistry;

    // ---
    // Constructor
    // ---

    constructor(INodeRegistry _nodeRegistry, Collection _implementation) {
        implementation = _implementation;
        nodeRegistry = _nodeRegistry;
    }

    // ---
    // Public functionality
    // ---

    /// @notice Deploy a new collection.
    function createCollection(CreateCollectionConfig calldata config)
        external
        returns (Collection collection)
    {
        // msg.sender must be authorized to manage the control node of the new
        // collection
        if (
            !nodeRegistry.isAuthorizedAddressForNode(
                config.controlNodeId,
                msg.sender
            )
        ) {
            revert NotAuthorized();
        }

        collection = Collection(Clones.clone(address(implementation)));
        collection.init(
            config.owner,
            AccessControlData({
                nodeRegistry: nodeRegistry,
                controlNodeId: config.controlNodeId
            }),
            config.metadata,
            ImmutableCollectionData({
                name: config.name,
                symbol: config.symbol,
                contractURI: config.contractURI
            })
        );
        emit CollectionCreated(address(collection));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/*

███╗   ███╗███████╗████████╗ █████╗ ██╗      █████╗ ██████╗ ███████╗██╗
████╗ ████║██╔════╝╚══██╔══╝██╔══██╗██║     ██╔══██╗██╔══██╗██╔════╝██║
██╔████╔██║█████╗     ██║   ███████║██║     ███████║██████╔╝█████╗  ██║
██║╚██╔╝██║██╔══╝     ██║   ██╔══██║██║     ██╔══██║██╔══██╗██╔══╝  ██║
██║ ╚═╝ ██║███████╗   ██║   ██║  ██║███████╗██║  ██║██████╔╝███████╗███████╗
╚═╝     ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚══════╝


Deployed by Metalabel with 💖 as a permanent application on the Ethereum blockchain.

Metalabel is a growing universe of tools, knowledge, and resources for
metalabels and cultural collectives.

Our purpose is to establish the metalabel as key infrastructure for creative
collectives and to inspire a new culture of creative collaboration and mutual
support.

OUR SQUAD

Anna Bulbrook (Curator)
Austin Robey (Community)
Brandon Valosek (Engineer)
Ilya Yudanov (Designer)
Lauren Dorman (Engineer)
Rob Kalin (Board)
Yancey Strickler (Director)

https://metalabel.xyz

*/

import {Owned} from "@metalabel/solmate/src/auth/Owned.sol";
import {MerkleProofLib} from "@metalabel/solmate/src/utils/MerkleProofLib.sol";
import {IAccountRegistry} from "./interfaces/IAccountRegistry.sol";
import {INodeRegistry, NodeType} from "./interfaces/INodeRegistry.sol";
import {SequenceData} from "./interfaces/IEngine.sol";
import {CollectionFactory, CreateCollectionConfig} from "./CollectionFactory.sol";
import {MembershipsFactory, CreateMembershipsConfig} from "./MembershipsFactory.sol";
import {Memberships, AdminMembershipMint} from "./Memberships.sol";
import {Collection} from "./Collection.sol";

/// @notice Information provided by the Metalabel core team when issuing a new
/// account via this controller
struct IssueAccountConfig {
    address subject;
    string metadata;
}

/// @notice Information provided when setting up a metalabel
struct SetupMetalabelConfig {
    uint64 metalabelNodeId;
    string subdomain;
    string collectionName;
    string collectionSymbol;
    string collectionContractURI;
    string collectionMetadata;
    string membershipsName;
    string membershipsSymbol;
    string membershipsBaseURI;
    string membershipsMetadata;
    bytes32 membershipsListRoot;
    AdminMembershipMint[] members;
    bytes32[] proof;
}

/// @notice Data used when configuring new sequences when publishing a release
struct SequenceConfig {
    SequenceData sequenceData;
    bytes engineData;
}

/// @notice Information provided when publishing a new release
struct PublishReleaseConfig {
    uint64 metalabelNodeId;
    string releaseMetadata;
    Collection recordCollection;
    SequenceConfig[] sequences;
}

/// @notice Controller that batches steps required for launching a metalabel,
/// publishing a release, and allowlisting new accounts.
contract ControllerV1 is Owned {
    // ---
    // Errors
    // ---

    /// @notice Happens if a metalabel is attempted to be setup more than once
    error SubdomainAlreadyReserved();

    /// @notice An invalid merkle proof was provided
    error InvalidProof();

    /// @notice An action was attempted by a msg.sender that is not authorized
    /// for a node.
    error NotAuthorized();

    // ---
    // Events
    // ---

    /// @notice A subdomain was reserved for a metalabel
    event SubdomainReserved(uint64 indexed metalabelNodeId, string subdomain);

    /// @notice The allowlist root was updated
    event AllowlistRootUpdated(bytes32 allowlistRoot);

    // ---
    // Storage
    // ---

    /// @notice Reference to the node registry of the protocol.
    INodeRegistry public immutable nodeRegistry;

    /// @notice Reference to the account registry of the protocol.
    IAccountRegistry public immutable accountRegistry;

    /// @notice Reference to the collection factory of the protocol.
    CollectionFactory public immutable collectionFactory;

    /// @notice Reference to the memberships factory of the protocol.
    MembershipsFactory public immutable membershipsFactory;

    /// @notice Mapping of subdomains to metalabel node IDs - used to check if
    /// the subdomain has already been reserved
    mapping(string => uint64) public subdomains;

    /// @notice The merkle root of the allowlist tree
    bytes32 public allowlistRoot;

    constructor(
        INodeRegistry _nodeRegistry,
        IAccountRegistry _accountRegistry,
        CollectionFactory _collectionFactory,
        MembershipsFactory _membershipsFactory,
        address _contractOwner
    ) Owned(_contractOwner) {
        nodeRegistry = _nodeRegistry;
        accountRegistry = _accountRegistry;
        collectionFactory = _collectionFactory;
        membershipsFactory = _membershipsFactory;
    }

    // ---
    // Admin / owner functionality
    // ---

    /// @notice Update the allowlist root and issue any accounts. This method is
    /// called by the metalabel core team to create new accounts for admins and
    /// allowlist setting up their metalabels.
    /// @dev This contract will be added as an authorized account issuer in
    /// AccountRegistry. This means whoever is the owner of this contract can
    /// use this function to issue accounts to _any_ address they want, which is
    /// fine (both will be controlled internally by the same address).
    /// This is only needed because account issuance in AccountRegistry is
    /// currently permissioned. If the protocol is switched to permissionless
    /// account issuance, this method will no longer be needed
    function updateAllowlist(
        bytes32 _allowlistRoot,
        IssueAccountConfig[] calldata accountsToIssue
    ) external onlyOwner {
        // Update root
        allowlistRoot = _allowlistRoot;
        emit AllowlistRootUpdated(_allowlistRoot);

        for (uint256 i = 0; i < accountsToIssue.length; i++) {
            accountRegistry.createAccount(
                accountsToIssue[i].subject,
                accountsToIssue[i].metadata
            );
        }
    }

    // ---
    // Metalabel functionality
    // ---

    /// @notice Setup a metalabel. Happens after the admin has already had an
    /// account created for this and has created the metalabel node themselves
    /// by directly interacting with NodeRegistry. The admin must have this
    /// contract set as an authorized controller for this method to work.
    /// - Assert msg.sender and subdomain are on the allowlist via merkle proof
    /// - Assert msg.sender can manage the metalabel node
    /// - Mark the subdomain as reserved
    /// - Launch the record collection
    /// - Launch the memberships collection (if merkle root is not zero)
    /// - Mint initial membership NFTs (if merkle root is not zero)
    function setupMetalabel(SetupMetalabelConfig calldata config)
        external
        returns (Collection recordCollection, Memberships memberships)
    {
        // Assert setup is allowed - sender must provide a merkle proof of their
        // (subdomain, admin) pair.
        bool isValid = MerkleProofLib.verify(
            config.proof,
            allowlistRoot,
            keccak256(abi.encodePacked(config.subdomain, msg.sender))
        );
        if (!isValid) {
            revert InvalidProof();
        }

        // Assert that msg.sender can manage the metalabel. Since this is an
        // authorized controller, we cannot skip checking authorization since
        // several nodes may have authorized this address
        if (
            !nodeRegistry.isAuthorizedAddressForNode(
                config.metalabelNodeId,
                msg.sender
            )
        ) {
            revert NotAuthorized();
        }

        // Assert not yet setup and mark the subdomain as reserved for this
        // metalabel. This is read offchain for the frontend to know what
        // subdomain belongs to what metalabel.
        if (subdomains[config.subdomain] != 0) {
            revert SubdomainAlreadyReserved();
        }
        subdomains[config.subdomain] = config.metalabelNodeId;
        emit SubdomainReserved(config.metalabelNodeId, config.subdomain);

        // Deploy the record collection. We already know msg.sender is
        // authorized to manage the metalabel node, so no additional checks are
        // required here. The control node is set to the metalabel, so access
        // control is inherited from the metalabel.
        recordCollection = collectionFactory.createCollection(
            CreateCollectionConfig({
                name: config.collectionName,
                symbol: config.collectionSymbol,
                contractURI: config.collectionContractURI,
                owner: msg.sender,
                controlNodeId: config.metalabelNodeId,
                metadata: config.collectionMetadata
            })
        );

        // If the memberships list root is 0, then skip deploying the membership
        // collection
        if (config.membershipsListRoot == 0) {
            // memberships will be the zero address since it wasn't deployed
            return (recordCollection, memberships);
        }

        // Deploy the memberships collection. We already know msg.sender is
        // authorized to manage the metalabel node, so no additional checks are
        // required here. The control node is set to the metalabel, so access
        // control is inherited from the metalabel security.
        memberships = membershipsFactory.createMemberships(
            CreateMembershipsConfig({
                name: config.membershipsName,
                symbol: config.membershipsSymbol,
                baseURI: config.membershipsBaseURI,
                owner: msg.sender,
                controlNodeId: config.metalabelNodeId,
                metadata: config.membershipsMetadata
            })
        );

        // Admin mint the initial memberships and set the starting Merkle root.
        // Members could be empty if instead individual members will mint their
        // own memberships (using a Merkle proof). This contract can call this
        // function because its authorized to manage the membership's control
        // node (the metalabel).
        memberships.updateMemberships(
            config.membershipsListRoot,
            config.members,
            new uint256[](0)
        );
    }

    /// @notice Publish a release and configure a new DropEngineV2 sequence.
    /// This happens after a metalabel has already been launched by an admin and
    /// setup using the above method. The admin must have this contract set as
    /// an authorized controller for this method to work.
    function publishRelease(PublishReleaseConfig calldata config)
        external
        returns (uint64 releaseNodeId)
    {
        // Ensure that msg.sender can actually manage the metalabel node. Since
        // this is an authorized controller, we cannot skip checking
        // authorization since several nodes may have authorized this address
        if (
            !nodeRegistry.isAuthorizedAddressForNode(
                config.metalabelNodeId,
                msg.sender
            )
        ) {
            revert NotAuthorized();
        }

        // Create the release node as a child node to the metalabel. Node owner
        // is set to zero while group node is set to the metalabel, allowing
        // access control to be inherited from the metalabel node.
        // Also not adding this controller to the list of controllers for the
        // node - we are fully relying on the group node for access control.
        // We already checked that msg.sender is authorized to manage the
        // metalabel, so no additional checks are required for this call.
        releaseNodeId = nodeRegistry.createNode(
            NodeType.RELEASE,
            0, /* no owner - access control comes from the group */
            config.metalabelNodeId, /* parent = metalabel */
            config.metalabelNodeId, /* group = metalabel */
            new address[](0), /* no controllers, access control comes from the group */
            config.releaseMetadata
        );

        // Assert sender can manage the record collection. Similar to above, we
        // must do this check since this controller may be authorized by several
        // metalabels. If the sender used setupMetalabel, then this check will
        // always return true, but we still check in case there was another
        // collection setup outside of this controller.
        if (
            !nodeRegistry.isAuthorizedAddressForNode(
                config.recordCollection.controlNode(),
                msg.sender
            )
        ) {
            revert NotAuthorized();
        }

        // A release may have zero or more sequences created at the same time
        // the catalog node is created.
        for (uint256 i = 0; i < config.sequences.length; i++) {
            // Overrwrite the release node ID to reference the release node we
            // just created, attaching this sequence to the new release. We do
            // this instead of allowing the caller to specify the release node
            // to ensure the sequences created via publishRelease are always
            // attached to the release node created by this method.
            SequenceData memory sequenceData = config.sequences[i].sequenceData;
            sequenceData.dropNodeId = releaseNodeId;

            // Setup the new drop. We don't need to do any access checks since
            // the drop node is the new release node. Since the release node has
            // the metalabel as a group node, the release node inherits the same
            // access control (so this controller can create a new drop for it).
            config.recordCollection.configureSequence(
                sequenceData,
                config.sequences[i].engineData
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @notice The account registry manages mappings from an address to an account
/// ID.
interface IAccountRegistry {
    /// @notice Permissionlessly create a new account for the subject address.
    /// Subject must not yet have an account.
    function createAccount(address subject, string calldata metadata)
        external
        returns (uint64 id);

    /// @notice Get the account ID for an address. Will revert if the address
    /// does not have an account
    function resolveId(address subject) external view returns (uint64 id);

    /// @notice Attempt to get the account ID for an address, and return 0 if
    /// the account does not exist. This is generally not recommended, as the
    /// caller must be careful to handle the zero-case to avoid potential access
    /// control pitfalls or bugs.
    /// @dev Prefer `resolveId` if possible. If you must use this function,
    /// ensure the zero-case is handled correctly.
    function unsafeResolveId(address subject) external view returns (uint64 id);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {SequenceData} from "./IEngine.sol";

/// @notice Collections are ERC721 contracts that contain records.
interface ICollection {
    /// @notice Mint a new record with custom immutable token data. Only
    /// callable by the sequence-specific engine.
    function mintRecord(
        address to,
        uint16 sequenceId,
        uint80 tokenData
    ) external returns (uint256 tokenId);

    /// @notice Mint a new record with the edition number of the sequence
    /// written to the immutable token data. Only callable by the
    /// sequence-specific engine.
    function mintRecord(address to, uint16 sequenceId)
        external
        returns (uint256 tokenId);

    /// @notice Get the sequence ID for a given token.
    function tokenSequenceId(uint256 tokenId)
        external
        view
        returns (uint16 sequenceId);

    /// @notice Get the immutable mint data for a given token.
    function tokenMintData(uint256 tokenId) external view returns (uint80 data);

    /// @notice Get the sequence data for a given sequence ID.
    function getSequenceData(uint16 sequenceId)
        external
        view
        returns (SequenceData memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @notice Data stored in the collection for each sequence.
/// @dev We could use smaller ints for timestamps and supply, but we'd still be
/// stuck with a 2-word storage layout. engine + dropNodeId is 28 bytes, leaving
/// us with only 4 bytes for the remaining parameters.
struct SequenceData {
    uint64 sealedBeforeTimestamp;
    uint64 sealedAfterTimestamp;
    uint64 maxSupply;
    uint64 minted;
    // ^ 1 word
    IEngine engine;
    uint64 dropNodeId;
    // 4 bytes remaining
}

/// @notice An engine contract implements record minting mechanics, tokenURI
/// computation, and royalty computation.
interface IEngine {
    /// @notice Called by the collection when a new sequence is configured.
    /// @dev An arbitrary bytes buffer engineData is forwarded from the
    /// collection that can be used to pass setup and configuration data
    function configureSequence(
        uint16 sequenceId,
        SequenceData calldata sequence,
        bytes calldata engineData
    ) external;

    /// @notice Called by the collection to resolve tokenURI.
    function getTokenURI(address collection, uint256 tokenId)
        external
        view
        returns (string memory);

    /// @notice Called by the collection to resolve royalties.
    function getRoyaltyInfo(
        address collection,
        uint256 tokenId,
        uint256 salePrice
    ) external view returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

enum NodeType {
    INVALID_NODE_TYPE,
    METALABEL,
    RELEASE
}

/// @notice Data stored per node.
struct NodeData {
    NodeType nodeType;
    uint64 owner;
    uint64 parent;
    uint64 groupNode;
    // 7 bytes remaining
}

/// @notice The node registry maintains a tree of ownable nodes that are used to
/// catalog logical entities and manage access control in the Metalabel
/// universe.
interface INodeRegistry {
    /// @notice Create a new node. Child nodes can specify an group node that
    /// will be used to determine ownership, and a separate logical parent that
    /// expresses the entity relationship.  Child nodes can only be created if
    /// msg.sender is an authorized manager of the parent node.
    function createNode(
        NodeType nodeType,
        uint64 owner,
        uint64 parent,
        uint64 groupNode,
        address[] memory initialControllers,
        string memory metadata
    ) external returns (uint64 id);

    /// @notice Determine if an address is authorized to manage a node.
    /// A node can be managed by an address if any of the following conditions
    /// are true:
    ///   - The address's account is the owner of the node
    ///   - The address's account is the owner of the node's group node
    ///   - The address is an authorized controller of the node
    ///   - The address is an authorized controller of the node's group node
    function isAuthorizedAddressForNode(uint64 node, address subject)
        external
        view
        returns (bool isAuthorized);

    /// @notice Resolve node owner account.
    function ownerOf(uint64 id) external view returns (uint64);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {INodeRegistry} from "./INodeRegistry.sol";

/// @notice An on-chain resource that is intended to be cataloged within the
/// Metalabel universe
interface IResource {
    /// @notice Broadcast an arbitrary message.
    event Broadcast(string topic, string message);

    /// @notice Return the node registry contract address.
    function nodeRegistry() external view returns (INodeRegistry);

    /// @notice Return the control node ID for this resource.
    function controlNode() external view returns (uint64 nodeId);

    /// @notice Return true if the given address is authorized to manage this
    /// resource.
    function isAuthorized(address subject)
        external
        view
        returns (bool authorized);

    /// @notice Emit an on-chain message. msg.sender must be authorized to
    /// manage this resource's control node
    function broadcast(string calldata topic, string calldata message) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/*

███╗   ███╗███████╗████████╗ █████╗ ██╗      █████╗ ██████╗ ███████╗██╗
████╗ ████║██╔════╝╚══██╔══╝██╔══██╗██║     ██╔══██╗██╔══██╗██╔════╝██║
██╔████╔██║█████╗     ██║   ███████║██║     ███████║██████╔╝█████╗  ██║
██║╚██╔╝██║██╔══╝     ██║   ██╔══██║██║     ██╔══██║██╔══██╗██╔══╝  ██║
██║ ╚═╝ ██║███████╗   ██║   ██║  ██║███████╗██║  ██║██████╔╝███████╗███████╗
╚═╝     ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚══════╝


Deployed by Metalabel with 💖 as a permanent application on the Ethereum blockchain.

Metalabel is a growing universe of tools, knowledge, and resources for
metalabels and cultural collectives.

Our purpose is to establish the metalabel as key infrastructure for creative
collectives and to inspire a new culture of creative collaboration and mutual
support.

OUR SQUAD

Anna Bulbrook (Curator)
Austin Robey (Community)
Brandon Valosek (Engineer)
Ilya Yudanov (Designer)
Lauren Dorman (Engineer)
Rob Kalin (Board)
Yancey Strickler (Director)

https://metalabel.xyz

*/

import {ERC721} from "@metalabel/solmate/src/tokens/ERC721.sol";
import {MerkleProofLib} from "@metalabel/solmate/src/utils/MerkleProofLib.sol";
import {SSTORE2} from "@metalabel/solmate/src/utils/SSTORE2.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {INodeRegistry} from "./interfaces/INodeRegistry.sol";
import {Resource, AccessControlData} from "./Resource.sol";

/// @notice Immutable data stored per-collection.
/// @dev This is stored via SSTORE2 to save gas.
struct ImmutableCollectionData {
    string name;
    string symbol;
    string baseURI;
}

/// @notice Data required when doing a permissionless mint via proof.
struct MembershipMint {
    address to;
    uint16 sequenceId;
    bytes32[] proof;
}

/// @notice Data required when doing an admin mint.
/// @dev Admin mints do not require a providing a proof to keep gas down.
struct AdminMembershipMint {
    address to;
    uint16 sequenceId;
}

/// @notice Data for supply and next ID.
/// @dev Fits into a single storage slot to keep gas cost down during minting.
struct MembershipsState {
    uint128 totalSupply;
    uint128 totalMinted;
}

/// @notice Membership collections can have their metadata resolver set to an
/// external contract
/// @dev This is used to futureproof the membership collection -- if a squad
/// wants to move to a more onchain approach to membership metadata or have an
/// alternative renderer, this gives them the option
interface ICustomMetadataResolver {
    /// @notice Resolve the token URI for a collection / token.
    function tokenURI(address collection, uint256 tokenId)
        external
        view
        returns (string memory);

    /// @notice Resolve the collection URI for a collection.
    function contractURI(address collection)
        external
        view
        returns (string memory);
}

/// @notice An ERC721 collection of NFTs representing memberships.
/// - NFTs are non-transferable
/// - Each membership collection has a control node, determining who the admin is
/// - Admin can unilaterally mint and burn memberships, without proofs to keep
///   gas down.
/// - Admin can use a merkle root to set a large list of memberships that can be
///   minted by anyone with a valid proof to socialize gas
/// - Token URI computation defaults to baseURI + tokenID, but can be modified
///   by a future external metadata resolver contract that implements
///   ICustomMetadataResolver
/// - Each token stores the mint timestamp, as well as an arbitrary sequence ID.
///   Sequence ID has no onchain consequence, but can be set by the admin if
///   desired
contract Memberships is ERC721, Resource {
    // ---
    // Errors
    // ---

    /// @notice The init function was called more than once.
    error AlreadyInitialized();

    /// @notice Attempted to transfer a membership NFT.
    error TransferNotAllowed();

    /// @notice Attempted to mint an invalid membership.
    error InvalidMint();

    /// @notice Attempted to burn an invalid or unowned membership token.
    error InvalidBurn();

    /// @notice Attempted to admin transfer a membership to somebody who already has one.
    error InvalidTransfer();

    // ---
    // Events
    // ---

    /// @notice A new membership NFT was minted.
    /// @dev The underlying ERC721 implementation already emits a Transfer event
    /// on mint, this additional event announces the sequence ID and timestamp
    /// associated with that membership.
    event MembershipCreated(
        uint256 indexed tokenId,
        uint16 sequenceId,
        uint80 timestamp
    );

    /// @notice The merkle root of the membership list was updated.
    event MembershipListRootUpdated(bytes32 root);

    /// @notice The custom metadata resolver was updated.
    event CustomMetadataResolverUpdated(ICustomMetadataResolver resolver);

    /// @notice The owner address of this memberships collection was updated.
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    // ---
    // Storage
    // ---

    /// @notice Only for marketplace interop, can be set by owner of the control
    /// node.
    address public owner;

    /// @notice Merkle root of the membership list.
    bytes32 public membershipListRoot;

    /// @notice If a custom metadata resolver is set, it will be used to resolve
    /// tokenURI and collectionURI values
    ICustomMetadataResolver public customMetadataResolver;

    /// @notice Tracks total supply and next ID
    /// @dev These values are exposed via totalSupply and totalMinted views.
    MembershipsState internal membershipState;

    /// @notice The SSTORE2 storage pointer for immutable collection data.
    /// @dev These values are exposed via name/symbol/contractURI views.
    address internal immutableStoragePointer;

    // ---
    // Constructor
    // ---

    /// @dev Constructor only called during deployment of the implementation,
    /// all storage should be set up in init function which is called atomically
    /// after clone deployment
    constructor() {
        // Write dummy data to the immutable storage pointer to prevent
        // initialization of the implementation contract.
        immutableStoragePointer = SSTORE2.write(
            abi.encode(
                ImmutableCollectionData({name: "", symbol: "", baseURI: ""})
            )
        );
    }

    // ---
    // Clone init
    // ---

    /// @notice Initialize contract state.
    /// @dev Should be called immediately after deploying the clone in the same transaction.
    function init(
        address _owner,
        AccessControlData calldata _accessControl,
        string calldata _metadata,
        ImmutableCollectionData calldata _data
    ) external {
        if (immutableStoragePointer != address(0)) revert AlreadyInitialized();
        immutableStoragePointer = SSTORE2.write(abi.encode(_data));

        // Set ERC721 market interop.
        owner = _owner;
        emit OwnershipTransferred(address(0), owner);

        // Assign access control data.
        accessControl = _accessControl;

        // This memberships collection is a resource that can be cataloged -
        // emit the initial metadata value
        emit Broadcast("metadata", _metadata);
    }

    // ---
    // Admin functionality
    // ---

    /// @notice Change the owner address of this collection.
    /// @dev This is only here for market interop, access control is handled via
    /// the control node.
    function setOwner(address _owner) external onlyAuthorized {
        address previousOwner = owner;
        owner = _owner;
        emit OwnershipTransferred(previousOwner, _owner);
    }

    /// @notice Change the merkle root of the membership list. Only callable by
    /// the admin
    function setMembershipListRoot(bytes32 _root) external onlyAuthorized {
        membershipListRoot = _root;
        emit MembershipListRootUpdated(_root);
    }

    /// @notice Set the custom metadata resolver. Passing in address(0) will
    /// effectively clear the custom resolver. Only callable by the admin.
    function setCustomMetadataResolver(ICustomMetadataResolver _resolver)
        external
        onlyAuthorized
    {
        customMetadataResolver = _resolver;
        emit CustomMetadataResolverUpdated(_resolver);
    }

    /// @notice Issue or revoke memberships without having to provide proofs.
    /// Only callable by the admin.
    function batchMintAndBurn(
        AdminMembershipMint[] calldata mints,
        uint256[] calldata burns
    ) external onlyAuthorized {
        _mintAndBurn(mints, burns);
    }

    /// @notice Update the membership list root and burn / mint memberships.
    /// @dev This is a convenience function for the admin to update things all
    /// at once; when adding or removing members, we can update the root, and
    /// issue/revoke memberships for the changes.
    function updateMemberships(
        bytes32 _root,
        AdminMembershipMint[] calldata mints,
        uint256[] calldata burns
    ) external onlyAuthorized {
        membershipListRoot = _root;
        emit MembershipListRootUpdated(_root);
        _mintAndBurn(mints, burns);
    }

    /// @dev Admin (proofless) mint and burn implementation
    function _mintAndBurn(
        AdminMembershipMint[] memory mints,
        uint256[] memory burns
    ) internal {
        MembershipsState storage state = membershipState;
        uint128 minted = state.totalMinted;

        // mint new ones
        for (uint256 i = 0; i < mints.length; i++) {
            // enforce at-most-one membership per address
            if (balanceOf(mints[i].to) > 0) revert InvalidMint();
            _mint(
                mints[i].to,
                ++minted,
                mints[i].sequenceId,
                uint80(block.timestamp)
            );
            emit MembershipCreated(
                minted,
                mints[i].sequenceId,
                uint80(block.timestamp)
            );
        }

        // burn old ones - the underlying implementation will revert if tokenID
        // is invalid
        for (uint256 i = 0; i < burns.length; i++) {
            _burn(burns[i]);
        }

        // update state
        state.totalMinted = minted;
        state.totalSupply =
            state.totalSupply +
            uint128(mints.length) -
            uint128(burns.length);
    }

    // ---
    // Permissionless mint
    // ---

    /// @notice Mint any unminted memberships that are on the membership list.
    /// Can be called by anyone since each mint requires a proof.
    function mintMemberships(MembershipMint[] calldata mints) external {
        MembershipsState storage state = membershipState;
        uint128 minted = state.totalMinted;
        uint128 supply = state.totalSupply;

        // for each mint request, verify the proof and mint the token
        for (uint256 i = 0; i < mints.length; i++) {
            // enforce at-most-one membership per address
            if (balanceOf(mints[i].to) > 0) revert InvalidMint();
            bool isValid = MerkleProofLib.verify(
                mints[i].proof,
                membershipListRoot,
                keccak256(abi.encodePacked(mints[i].to, mints[i].sequenceId))
            );
            if (!isValid) revert InvalidMint();
            _mint(
                mints[i].to,
                ++minted,
                mints[i].sequenceId,
                uint80(block.timestamp)
            );
            emit MembershipCreated(
                minted,
                mints[i].sequenceId,
                uint80(block.timestamp)
            );
            supply++;
        }

        // Write new counts back to storage
        state.totalMinted = minted;
        state.totalSupply = supply;
    }

    // ---
    // Token holder functionality
    // ---

    /// @notice Burn a membership. Msg sender must own token.
    function burnMembership(uint256 tokenId) external {
        if (ownerOf(tokenId) != msg.sender) revert InvalidBurn();
        _burn(tokenId);
        membershipState.totalSupply--;
    }

    // ---
    // ERC721 functionality - non-transferability / admin transfers
    // ---

    /// @notice Transfer is not allowed on this token.
    function transferFrom(
        address,
        address,
        uint256
    ) public pure override {
        revert TransferNotAllowed();
    }

    /// @notice Transfer an existing membership from one address to another. Only
    /// callable by the admin.
    function adminTransferFrom(
        address from,
        address to,
        uint256 id
    ) external onlyAuthorized {
        if (from == address(0)) revert InvalidTransfer();
        if (to == address(0)) revert InvalidTransfer();
        if (balanceOf(to) != 0) revert InvalidTransfer();
        if (from != _tokenData[id].owner) revert InvalidTransfer();

        //
        // The below code was copied from the solmate transferFrom source,
        // removing the checks (which we've already done above)
        //
        // --- START COPIED CODE ---
        //

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;
            _balanceOf[to]++;
        }

        _tokenData[id].owner = to;
        delete getApproved[id];
        emit Transfer(from, to, id);

        //
        // --- END COPIED CODE ---
        //
    }

    // ---
    // ERC721 views
    // ---

    /// @notice The collection name.
    function name() public view virtual returns (string memory value) {
        value = _resolveImmutableStorage().name;
    }

    /// @notice The collection symbol.
    function symbol() public view virtual returns (string memory value) {
        value = _resolveImmutableStorage().symbol;
    }

    /// @inheritdoc ERC721
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory uri)
    {
        // If a custom metadata resolver is set, use it to get the token URI
        // instead of the default behavior
        if (customMetadataResolver != ICustomMetadataResolver(address(0))) {
            return customMetadataResolver.tokenURI(address(this), tokenId);
        }

        // Form URI from base + collection + token ID
        uri = string.concat(
            _resolveImmutableStorage().baseURI,
            Strings.toHexString(address(this)),
            "/",
            Strings.toString(tokenId),
            ".json"
        );
    }

    /// @notice Get the collection URI
    function contractURI() public view virtual returns (string memory uri) {
        // If a custom metadata resolver is set, use it to get the collection
        // URI instead of the default behavior
        if (customMetadataResolver != ICustomMetadataResolver(address(0))) {
            return customMetadataResolver.contractURI(address(this));
        }

        // Form URI from base + collection
        uri = string.concat(
            _resolveImmutableStorage().baseURI,
            Strings.toHexString(address(this)),
            "/collection.json"
        );
    }

    // ---
    // Misc views
    // ---

    /// @notice Get a membership's sequence ID.
    function tokenSequenceId(uint256 tokenId)
        external
        view
        returns (uint16 sequenceId)
    {
        sequenceId = _tokenData[tokenId].sequenceId;
    }

    /// @notice Get a membership's mint timestamp.
    function tokenMintTimestamp(uint256 tokenId)
        external
        view
        returns (uint80 timestamp)
    {
        timestamp = _tokenData[tokenId].data;
    }

    /// @notice Get total supply of existing memberships.
    function totalSupply() public view virtual returns (uint256) {
        return membershipState.totalSupply;
    }

    /// @notice Get total count of minted memberships, including burned ones.
    function totalMinted() public view virtual returns (uint256) {
        return membershipState.totalMinted;
    }

    // ---
    // Internal views
    // ---

    function _resolveImmutableStorage()
        internal
        view
        returns (ImmutableCollectionData memory data)
    {
        data = abi.decode(
            SSTORE2.read(immutableStoragePointer),
            (ImmutableCollectionData)
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/*

███╗   ███╗███████╗████████╗ █████╗ ██╗      █████╗ ██████╗ ███████╗██╗
████╗ ████║██╔════╝╚══██╔══╝██╔══██╗██║     ██╔══██╗██╔══██╗██╔════╝██║
██╔████╔██║█████╗     ██║   ███████║██║     ███████║██████╔╝█████╗  ██║
██║╚██╔╝██║██╔══╝     ██║   ██╔══██║██║     ██╔══██║██╔══██╗██╔══╝  ██║
██║ ╚═╝ ██║███████╗   ██║   ██║  ██║███████╗██║  ██║██████╔╝███████╗███████╗
╚═╝     ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚══════╝


Deployed by Metalabel with 💖 as a permanent application on the Ethereum blockchain.

Metalabel is a growing universe of tools, knowledge, and resources for
metalabels and cultural collectives.

Our purpose is to establish the metalabel as key infrastructure for creative
collectives and to inspire a new culture of creative collaboration and mutual
support.

OUR SQUAD

Anna Bulbrook (Curator)
Austin Robey (Community)
Brandon Valosek (Engineer)
Ilya Yudanov (Designer)
Lauren Dorman (Engineer)
Rob Kalin (Board)
Yancey Strickler (Director)

https://metalabel.xyz

*/

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {INodeRegistry} from "./interfaces/INodeRegistry.sol";
import {Memberships, ImmutableCollectionData} from "./Memberships.sol";
import {AccessControlData} from "./Resource.sol";

/// @notice Configuration data required when deploying a new collection.
struct CreateMembershipsConfig {
    string name;
    string symbol;
    string baseURI;
    address owner;
    uint64 controlNodeId;
    string metadata;
}

/// @notice A factory that deploys memberships contract.
contract MembershipsFactory {
    // ---
    // Errors
    // ---

    /// @notice An unauthorized address attempted to create a memberships
    /// contract.
    error NotAuthorized();

    // ---
    // Events
    // ---

    /// @notice A new memberships contract was deployed
    event MembershipsCreated(Memberships indexed memberships);

    // ---
    // Storage
    // ---

    /// @notice Reference to the memberships implementation that will be cloned.
    Memberships public immutable implementation;

    /// @notice Reference to the node registry of the protocol.
    INodeRegistry public immutable nodeRegistry;

    // ---
    // Constructor
    // ---

    constructor(INodeRegistry _nodeRegistry, Memberships _implementation) {
        implementation = _implementation;
        nodeRegistry = _nodeRegistry;
    }

    // ---
    // Public functionality
    // ---

    /// @notice Deploy a new memberships NFT contract.
    function createMemberships(CreateMembershipsConfig calldata config)
        external
        returns (Memberships memberships)
    {
        // msg.sender must be authorized to manage the control node of the new
        // memberships collection.
        if (
            !nodeRegistry.isAuthorizedAddressForNode(
                config.controlNodeId,
                msg.sender
            )
        ) {
            revert NotAuthorized();
        }

        memberships = Memberships(Clones.clone(address(implementation)));
        memberships.init(
            config.owner,
            AccessControlData({
                nodeRegistry: nodeRegistry,
                controlNodeId: config.controlNodeId
            }),
            config.metadata,
            ImmutableCollectionData({
                name: config.name,
                symbol: config.symbol,
                baseURI: config.baseURI
            })
        );
        emit MembershipsCreated(memberships);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/*

███╗   ███╗███████╗████████╗ █████╗ ██╗      █████╗ ██████╗ ███████╗██╗
████╗ ████║██╔════╝╚══██╔══╝██╔══██╗██║     ██╔══██╗██╔══██╗██╔════╝██║
██╔████╔██║█████╗     ██║   ███████║██║     ███████║██████╔╝█████╗  ██║
██║╚██╔╝██║██╔══╝     ██║   ██╔══██║██║     ██╔══██║██╔══██╗██╔══╝  ██║
██║ ╚═╝ ██║███████╗   ██║   ██║  ██║███████╗██║  ██║██████╔╝███████╗███████╗
╚═╝     ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝ ╚══════╝╚══════╝


Deployed by Metalabel with 💖 as a permanent application on the Ethereum blockchain.

Metalabel is a growing universe of tools, knowledge, and resources for
metalabels and cultural collectives.

Our purpose is to establish the metalabel as key infrastructure for creative
collectives and to inspire a new culture of creative collaboration and mutual
support.

OUR SQUAD

Anna Bulbrook (Curator)
Austin Robey (Community)
Brandon Valosek (Engineer)
Ilya Yudanov (Designer)
Lauren Dorman (Engineer)
Rob Kalin (Board)
Yancey Strickler (Director)

https://metalabel.xyz

*/

import {IResource} from "./interfaces/IResource.sol";
import {INodeRegistry} from "./interfaces/INodeRegistry.sol";

/// @notice Data stored for handling access control resolution.
struct AccessControlData {
    INodeRegistry nodeRegistry;
    uint64 controlNodeId;
    // 4 bytes remaining
}

/// @notice A resource that can be cataloged on the Metalabel protocol.
contract Resource is IResource {
    // ---
    // Errors
    // ---

    /// @notice Unauthorized msg.sender attempted to interact with this resource
    error NotAuthorized();

    // ---
    // Storage
    // ---

    /// @notice Access control data for this resource.
    AccessControlData public accessControl;

    // ---
    // Modifiers
    // ---

    /// @dev Make a function only callable by a msg.sender that is authorized to
    /// manage the control node of this resource
    modifier onlyAuthorized() {
        if (
            !accessControl.nodeRegistry.isAuthorizedAddressForNode(
                accessControl.controlNodeId,
                msg.sender
            )
        ) {
            revert NotAuthorized();
        }
        _;
    }

    // ---
    // Admin functionality
    // ---

    /// @inheritdoc IResource
    function broadcast(string calldata topic, string calldata message)
        external
        onlyAuthorized
    {
        emit Broadcast(topic, message);
    }

    // ---
    // Resource views
    // ---

    /// @inheritdoc IResource
    function nodeRegistry() external view virtual returns (INodeRegistry) {
        return accessControl.nodeRegistry;
    }

    /// @inheritdoc IResource
    function controlNode() external view virtual returns (uint64 nodeId) {
        return accessControl.controlNodeId;
    }

    /// @inheritdoc IResource
    function isAuthorized(address subject)
        public
        view
        virtual
        returns (bool authorized)
    {
        authorized = accessControl.nodeRegistry.isAuthorizedAddressForNode(
            accessControl.controlNodeId,
            subject
        );
    }
}