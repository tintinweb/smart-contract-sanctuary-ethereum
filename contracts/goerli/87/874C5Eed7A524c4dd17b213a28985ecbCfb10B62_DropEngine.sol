// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Efficient library for creating string representations of integers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/LibString.sol)
/// @author Modified from Solady (https://github.com/Vectorized/solady/blob/main/src/utils/LibString.sol)
library LibString {
    function toString(uint256 value) internal pure returns (string memory str) {
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
pragma solidity ^0.8.13;

import {ICollection} from "../interfaces/ICollection.sol";
import {IEngine, SequenceData} from "../interfaces/IEngine.sol";
import {LibString} from "@metalabel/solmate/src/utils/LibString.sol";

/// @notice Data stored engine-side for each drop.
/// @dev Fits in a single storage slot. Price stored as uint80 means max price
/// per record is (2^80-1)/1e18 = 1,208,925 ETH. Royalty percentage is stored as
/// basis points, 5% = 500, max value of 100% = 10000 fits within 2byte int
struct DropData {
    uint80 price;
    uint16 royaltyBps;
    address payable revenueRecipient;
    // no bytes left
}

/// @notice Engine that implements a multi-NFT drop. In a given sequence:
/// - Token data stores edition number on mint (immutable)
/// - Token URIs are derived from as single base URI + edition number
/// - All tokens are the same price
/// - Primary sales and royalties go to the same revenue recipient
contract DropEngine is IEngine {
    // ---
    // Errors
    // ---

    /// @notice Invalid msg.value on purchase
    error IncorrectPaymentAmount();

    /// @notice If price or recipient is zero, they both have to be zero
    error InvalidPriceOrRecipient();

    /// @notice A permissioned mint or attempt to remove the mint authority was
    /// sent from an invalid msg.sender
    error NotMintAuthority();

    /// @notice A public mint was attempted for a sequence that currently has a
    /// mint authority set. Public mint opens after the mint authority is
    /// removed
    error PublicMintNotActive();

    // ---
    // Events
    // ---

    /// @notice A new drop was created.
    /// @dev The collection already emits a SequenceCreated event, we're
    /// emitting the additonal engine-specific data here.
    event DropCreated(
        address collection,
        uint16 sequenceId,
        uint80 price,
        uint16 royaltyBps,
        address recipient,
        string uriPrefix,
        address mintAuthorities
    );

    /// @notice The permissioned mint authority for a sequence was removed.
    event mintAuthoritiesCleared(address collection, uint16 sequenceId);

    // ---
    // Storage
    // ---

    /// @notice Drop data for a given collection + sequence ID.
    mapping(address => mapping(uint16 => DropData)) public drops;

    /// @notice Token URI prefix for a given collection + sequence ID
    /// @dev storing separately from DropData structure to save gas during
    /// storage reads on mint.
    mapping(address => mapping(uint16 => string)) public baseTokenURIs;

    /// @notice If set for a given collection / sequence, only this address can
    /// mint.
    mapping(address => mapping(uint16 => address)) public mintAuthorities;

    // ---
    // Mint functionality
    // ---

    /// @notice Mint a new record.
    function mint(ICollection collection, uint16 sequenceId)
        external
        payable
        returns (uint256 tokenId)
    {
        DropData storage drop = drops[address(collection)][sequenceId];
        if (msg.value != drop.price) revert IncorrectPaymentAmount();

        // Check if this sequence is permissioned -- so long as their is a mint
        // authority, public mint is not active
        if (mintAuthorities[address(collection)][sequenceId] != address(0)) {
            revert PublicMintNotActive();
        }

        // Immediately forward payment to the recipient
        if (drop.price > 0) {
            drop.revenueRecipient.transfer(msg.value);
        }

        // Collection enforces max mint supply and mint window. If collection is
        // a malicious contract, that does not impact any state in the engine.
        // If it's a valid protocol-deployed collection, then it will work as
        // expected.
        tokenId = collection.mintRecord(msg.sender, sequenceId);
    }

    // ---
    // Permissioned functionality
    // ---

    /// @notice Mint a new record to a specific address, only callable by the
    /// permissioned mint authority for the sequence.
    function permissionedMint(
        ICollection collection,
        uint16 sequenceId,
        address to
    ) external returns (uint256 tokenId) {
        // Ensure msg.sender is the permissioned mint authority
        if (mintAuthorities[address(collection)][sequenceId] != msg.sender) {
            revert NotMintAuthority();
        }

        // Not loading drop data here or sending ETH, permissioned mints are
        // free. Max supply and mint window are still enforced by the downstream
        // collection.

        tokenId = collection.mintRecord(to, sequenceId);
    }

    /// @notice Permanently remove the mint authority for a given sequence.
    function clearMintAuthority(ICollection collection, uint16 sequenceId)
        external
    {
        if (mintAuthorities[address(collection)][sequenceId] != msg.sender) {
            revert NotMintAuthority();
        }

        delete mintAuthorities[address(collection)][sequenceId];
        emit mintAuthoritiesCleared(address(collection), sequenceId);
    }

    // ---
    // IEngine setup
    // ---

    /// @inheritdoc IEngine
    /// @dev There is no access control on this function, we infer the
    /// collection from msg.sender, and use that to key the stored data. If
    /// somebody calls this function with bogus info (instead of it getting
    /// called via the collection), it just wastes storage but does not impact
    /// contract functionality
    function configureSequence(
        uint16 sequenceId,
        SequenceData calldata, /* sequenceData */
        bytes calldata engineData
    ) external {
        (
            uint80 price,
            uint16 royaltyBps,
            address payable recipient,
            string memory uriPrefix,
            address mintAuthority
        ) = abi.decode(engineData, (uint80, uint16, address, string, address));

        // Ensure both price and recipient are zero or both are non-zero
        if (
            (price == 0 && recipient != address(0)) ||
            (price != 0 && recipient == address(0))
        ) {
            revert InvalidPriceOrRecipient();
        }

        // Set the permissioned mint authority if provided
        if (mintAuthority != address(0)) {
            mintAuthorities[msg.sender][sequenceId] = mintAuthority;
        }

        // Write engine data (passed through from the collection when the
        // collection admin calls `configureSequence`) to a struct in the engine
        // with all the needed info.
        drops[msg.sender][sequenceId] = DropData({
            price: price,
            royaltyBps: royaltyBps,
            revenueRecipient: recipient
        });
        baseTokenURIs[msg.sender][sequenceId] = uriPrefix;
        emit DropCreated(
            msg.sender,
            sequenceId,
            price,
            royaltyBps,
            recipient,
            uriPrefix,
            mintAuthority
        );
    }

    // ---
    // IEngine views
    // ---

    /// @inheritdoc IEngine
    /// @dev Token URI is derived from the base URI + edition number. Edition
    /// number is written to immutable token data on mint.
    function getTokenURI(address collection, uint256 tokenId)
        external
        view
        override
        returns (string memory)
    {
        uint16 sequenceId = ICollection(collection).tokenSequenceId(tokenId);
        uint80 editionNumber = ICollection(collection).tokenMintData(tokenId);

        return
            string(
                abi.encodePacked(
                    baseTokenURIs[collection][sequenceId],
                    LibString.toString(editionNumber),
                    ".json"
                )
            );
    }

    /// @inheritdoc IEngine
    /// @dev Royalty bps and recipient is per-sequence.
    function getRoyaltyInfo(
        address collection,
        uint256 tokenId,
        uint256 salePrice
    ) external view override returns (address, uint256) {
        uint16 sequenceId = ICollection(collection).tokenSequenceId(tokenId);
        DropData memory drop = drops[collection][sequenceId];
        return (drop.revenueRecipient, (salePrice * drop.royaltyBps) / 10000);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// @notice Collections are ERC721 contracts that contain records.
interface ICollection {
    /// @notice Mint a new record with custom immutable token data. Only
    /// callable by the sequence-specific engine.
    function mintRecord(
        address to,
        uint16 sequenceId,
        uint80 tokenData
    ) external returns (uint256 tokenId);

    /// @notice Mint a new record with the edition number of the seqeuence
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/// @notice Data stored in the collection for each sequence.
/// @dev We could use smaller ints for timestamps and supply, but we'd still be
/// stuck with a 2-word storage layout. engine + dropNodeId is 28 bytes, leaving
/// us with only 4 bytes for the remaining parameters.
struct SequenceData {
    uint64 sealedBeforeTimestamp;
    uint64 sealedAfterTimestamp;
    uint64 maxSupply;
    uint64 minted;
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