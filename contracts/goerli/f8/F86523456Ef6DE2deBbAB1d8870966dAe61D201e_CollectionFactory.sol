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