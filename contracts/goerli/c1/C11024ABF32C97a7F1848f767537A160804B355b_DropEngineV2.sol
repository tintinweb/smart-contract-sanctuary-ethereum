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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
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
import {SSTORE2} from "@metalabel/solmate/src/utils/SSTORE2.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ICollection} from "../interfaces/ICollection.sol";
import {IEngine, SequenceData} from "../interfaces/IEngine.sol";
import {INodeRegistry} from "../interfaces/INodeRegistry.sol";

/// @notice Data stored engine-side for each drop.
/// - Royalty percentage is stored as basis points, eg 5% = 500
/// - If maxRecordPerTransaction is 0, there is not limit
/// - Protocol fee is written to drop data at configure-time to lock in protocol
///   fee and avoid an additional storage read at mint-time
struct DropData {
    uint96 price;
    uint16 royaltyBps;
    bool allowContractMints;
    bool randomizeMetadataVariants;
    uint8 maxRecordsPerTransaction;
    address revenueRecipient;
    uint16 primarySaleFeeBps;
    uint96 priceDecayPerDay;
    uint64 decayStopTimestamp;
    // 59 bytes total / 5 remaining for a two-word slot
}

/// @notice A single attribute of an NFT's metadata
struct NFTMetadataAttribute {
    string trait_type;
    string value;
}

/// @notice Metadata stored for a single record variant
/// @dev Storage is written via SSTORE2
struct NFTMetadata {
    string name;
    string description;
    string image;
    string external_url;
    string metalabel_record_variant_name;
    string metalabel_release_metadata_uri;
    uint16[] metalabel_record_contents;
    NFTMetadataAttribute[] attributes;
}

/// @notice Metalabel engine that implements a multi-NFT drop.
/// - All metadata is stored onchain via SSTORE2.
/// - Price can decay over time or be constant throughout the drop.
/// - Metadata variants can be p-randomized or fixed.
/// - Enabling or disabling smart contract mints is set per-sequence.
/// - Multiple records can be minted in a single trx, configurable per-sequence.
/// - The owner of this contract can set a primary sale fee that is taken from
///   all primary sales revenue and retained by this drop engine.
contract DropEngineV2 is IEngine, Owned {
    // ---
    // Errors
    // ---

    /// @notice Invalid msg.value on purchase
    error IncorrectPaymentAmount();

    /// @notice If price or recipient is zero, they both have to be zero
    error InvalidPriceOrRecipient();

    /// @notice An invalid value was used for the royalty bps.
    error InvalidRoyaltyBps();

    /// @notice An invalid value was used for the primary sale fee.
    error InvalidPrimarySaleFee();

    /// @notice If smart contract mints are not allowed, msg.sender must be an
    /// EOA
    error MinterMustBeEOA();

    /// @notice If minting more than the max allowed per transaction
    error InvalidMintAmount();

    /// @notice An invalid price decay stop time or per day decay was used.
    error InvalidPriceDecayConfig();

    /// @notice Unable to forward ETH to the revenue recipient or unable to
    /// withdraw funds
    error CouldNotTransferEth();

    // ---
    // Events
    // ---

    /// @notice A new drop was created.
    /// @dev The collection already emits a SequenceCreated event, we're
    /// emitting the additional engine-specific data here.
    event DropCreated(address collection, uint16 sequenceId, DropData dropData);

    /// @notice The primary sale for this drop engine was set
    event PrimarySaleFeeSet(uint16 primarySaleFeeBps);

    // ---
    // Storage
    // ---

    /// @notice Drop data for a given collection + sequence ID.
    mapping(address => mapping(uint16 => DropData)) public drops;

    /// @notice The SSTORE2 contract storage address for a given sequence's list
    /// of metadata variants
    mapping(address => mapping(uint16 => address))
        public metadataStoragePointers;

    /// @notice A primary sales fee that is paid at mint time. Can be adjusted
    /// by contract owner. Fee is written into the drop's DropData structure, so
    /// fee at configure-time is locked. Fees are accumulated in the contract
    /// and can be withdrawn by the contract owner
    uint16 public primarySaleFeeBps;

    /// @notice A reference to the core protocol's node registry.
    /// @dev While this is not directly used by the engine, it is surfaced in
    /// the onchain generated JSON metadata for records as a way of creating a
    /// concrete link back to the cataloging protocol.
    INodeRegistry public immutable nodeRegistry;

    // ---
    // Constructor
    // ---

    constructor(address _contractOwner, INodeRegistry _nodeRegistry)
        Owned(_contractOwner)
    {
        nodeRegistry = _nodeRegistry;
    }

    // ---
    // Admin functionality
    // ---

    /// @notice Set the primary sale fee for all drops configured on this
    /// engine. Only callable by owner
    function setPrimarySaleFeeBps(uint16 fee) external onlyOwner {
        if (fee > 10000) revert InvalidPrimarySaleFee();
        primarySaleFeeBps = fee;
        emit PrimarySaleFeeSet(fee);
    }

    // ---
    // Permissionless functions
    // ---

    /// @notice Transfer ETH from the contract that has accumulated from fees to
    /// the owner's account. Can be called by any address.
    function transferFeesToOwner() external {
        (bool success, ) = owner.call{value: address(this).balance}("");
        if (!success) revert CouldNotTransferEth();
    }

    // ---
    // Mint functionality
    // ---

    /// @notice Mint records. Returns the first token ID minted
    function mint(
        ICollection collection,
        uint16 sequenceId,
        uint8 count
    ) external payable returns (uint256 tokenId) {
        DropData storage drop = drops[address(collection)][sequenceId];

        // block SC mints if flagged
        if (!drop.allowContractMints && msg.sender != tx.origin) {
            revert MinterMustBeEOA();
        }

        // Ensure not minting too many
        if (
            drop.maxRecordsPerTransaction > 0 &&
            count > drop.maxRecordsPerTransaction
        ) {
            revert InvalidMintAmount();
        }

        // Resolve current unit price (which may change over time if there's a
        // price decay configuration) and total order price
        uint256 unitPrice = currentPrice(collection, sequenceId);
        uint256 orderPrice = unitPrice * count;

        // Ensure correct payment was sent with the transaction. Checking less
        // than to allow sender to overpay (likely happens for all decaying
        // prices). We refund the difference below.
        if (msg.value < orderPrice) {
            revert IncorrectPaymentAmount();
        }

        for (uint256 i = 0; i < count; i++) {
            // If collection is a malicious contract, that does not impact any
            // state in the engine.  If it's a valid protocol-deployed
            // collection, then it will work as expected.
            //
            // Collection enforces max mint supply and mint window, so we're not
            // checking that here
            uint256 id = collection.mintRecord(msg.sender, sequenceId);

            // return the first minted token ID, caller can infer subsequent
            // sequential IDs
            tokenId = tokenId != 0 ? tokenId : id;
        }

        // Amount to forward to the revenue recipient is the total order price
        // minus the locked-in primary sale fee that was recorded at
        // configure-time.  The remaining ETH (after refund) will stay in this
        // contract, withdrawable by the owner at a later date via
        // transferFeesToOwner
        uint256 amountToForward = orderPrice -
            ((orderPrice * drop.primarySaleFeeBps) / 10000);

        // Amount to refund message sender is any difference in order price and
        // msg.value. This happens if the caller overpays, which will generally
        // always happen on decaying price mints
        uint256 amountToRefund = msg.value > orderPrice
            ? msg.value - orderPrice
            : 0;

        // Refund caller
        if (amountToRefund > 0) {
            (bool success, ) = msg.sender.call{value: amountToRefund}("");
            if (!success) revert CouldNotTransferEth();
        }

        // Forward ETH to the revenue recipient
        if (amountToForward > 0) {
            (bool success, ) = drop.revenueRecipient.call{
                value: amountToForward
            }("");
            if (!success) revert CouldNotTransferEth();
        }
    }

    /// @notice Get the current price of a record in a given sequence. This will
    /// return a price even if the sequence is not currently mintable (i.e. the
    /// mint window hasn't started yet or the minting window has closed).
    function currentPrice(ICollection collection, uint16 sequenceId)
        public
        view
        returns (uint256 unitPrice)
    {
        DropData storage drop = drops[address(collection)][sequenceId];

        // Compute unit price based on decay and timestamp.
        // First compute how many seconds until the decay cutoff time, after
        // which price will remain constant. Then compute the marginal increase
        // in unit price by multiplying the base price by
        //
        //   (decay per day * seconds until decay stop) / 1 day
        //

        uint64 secondsBeforeDecayStop = block.timestamp <
            drop.decayStopTimestamp
            ? drop.decayStopTimestamp - uint64(block.timestamp)
            : 0;
        uint256 inflateUnitPriceBy = (uint256(drop.priceDecayPerDay) *
            secondsBeforeDecayStop) / 1 days;
        unitPrice = drop.price + inflateUnitPriceBy;
    }

    // ---
    // IEngine setup
    // ---

    /// @inheritdoc IEngine
    /// @dev There is no access control on this function, we infer the
    /// collection from msg.sender, and use that to key all stored data. If
    /// somebody calls this function with bogus info (instead of it getting
    /// called via the collection), it just wastes storage but does not impact
    /// contract functionality
    function configureSequence(
        uint16 sequenceId,
        SequenceData calldata sequenceData,
        bytes calldata engineData
    ) external override {
        (DropData memory dropData, NFTMetadata[] memory metadatas) = abi.decode(
            engineData,
            (DropData, NFTMetadata[])
        );

        // This drop is a "free drop" if and only if the price is zero and decay
        // per day is zero
        bool isFreeDrop = dropData.price == 0 && dropData.priceDecayPerDay == 0;

        // Ensure that if this is a free drop, there's no revenue recipient, and
        // vice versa
        if ((isFreeDrop) != (dropData.revenueRecipient == address(0))) {
            revert InvalidPriceOrRecipient();
        }

        // Don't allow setting a decay stop time in the past (or before the mint
        // window opens) unless it's zero.
        if (
            dropData.decayStopTimestamp != 0 &&
            (dropData.decayStopTimestamp < block.timestamp ||
                dropData.decayStopTimestamp <
                sequenceData.sealedBeforeTimestamp)
        ) {
            revert InvalidPriceDecayConfig();
        }

        // Don't allow setting a decay stop time after the mint window closes
        if (
            sequenceData.sealedAfterTimestamp > 0 && // sealed = 0 -> no end
            dropData.decayStopTimestamp > sequenceData.sealedAfterTimestamp
        ) {
            revert InvalidPriceDecayConfig();
        }

        // Ensure that if decay stop time is set, decay per day is set, and vice
        // versa
        if (
            (dropData.decayStopTimestamp == 0) !=
            (dropData.priceDecayPerDay == 0)
        ) {
            revert InvalidPriceDecayConfig();
        }

        // Ensure royaltyBps is in range
        if (dropData.royaltyBps > 10000) revert InvalidRoyaltyBps();

        // To ensure that creators know the protocol fee they are effectively
        // agreeing to during sequence creation time, we require that they set
        // the primary sale fee correctly here. This also ensures the drop
        // engine owner cannot frontrun a fee change
        if (dropData.primarySaleFeeBps != primarySaleFeeBps) {
            revert InvalidPrimarySaleFee();
        }

        // write metadata blob to chain
        metadataStoragePointers[msg.sender][sequenceId] = SSTORE2.write(
            abi.encode(metadatas)
        );

        // Write engine data (passed through from the collection when the
        // collection admin calls `configureSequence`) to a struct in the engine
        // with all the needed info.
        drops[msg.sender][sequenceId] = dropData;
        emit DropCreated(msg.sender, sequenceId, dropData);
    }

    // ---
    // IEngine views
    // ---

    /// @inheritdoc IEngine
    /// @dev Token URI is constructed programmatically from stored metadata by
    /// creating the JSON string and base64ing it
    function getTokenURI(address collection, uint256 tokenId)
        external
        view
        override
        returns (string memory tokenURI)
    {
        uint16 sequenceId = ICollection(collection).tokenSequenceId(tokenId);
        uint80 editionNumber = ICollection(collection).tokenMintData(tokenId);
        SequenceData memory sequenceData = ICollection(collection)
            .getSequenceData(sequenceId);

        NFTMetadata memory metadata = getStoredMetadataVariant(
            collection,
            tokenId
        );

        // Construct edition string as either "1" or "1/1000" depending on if
        // this was an open edition
        string memory sEdition = sequenceData.maxSupply == 0
            ? Strings.toString(editionNumber)
            : string.concat(
                Strings.toString(editionNumber),
                "/",
                Strings.toString(sequenceData.maxSupply)
            );

        // Edition number and variant name are always included
        string memory attributesInnerJson = string.concat(
            '{"trait_type": "Record Edition", "value": "',
            sEdition,
            '"}, {"trait_type": "Record Variant", "value": "',
            metadata.metalabel_record_variant_name,
            '"}',
            metadata.attributes.length > 0 ? ", " : ""
        );

        // Additional attributes from metadata blob
        for (uint256 i = 0; i < metadata.attributes.length; i++) {
            attributesInnerJson = string.concat(
                attributesInnerJson,
                i > 0 ? ", " : "",
                '{"trait_type": "',
                metadata.attributes[i].trait_type,
                '", "value": "',
                metadata.attributes[i].value,
                '"}'
            );
        }

        // create the contents array
        string memory contentsInnerJson = "[";
        for (
            uint256 i = 0;
            i < metadata.metalabel_record_contents.length;
            i++
        ) {
            contentsInnerJson = string.concat(
                contentsInnerJson,
                Strings.toString(metadata.metalabel_record_contents[i]),
                i == metadata.metalabel_record_contents.length - 1 ? "]" : ", "
            );
        }

        // Compose the final JSON payload. Split across multiple string.concat
        // calls due to stack limitations
        string memory json = string.concat(
            '{"name":"',
            metadata.name,
            " ",
            sEdition,
            '", "description":"',
            metadata.description,
            '", "image": "',
            metadata.image,
            '", "external_url": "',
            metadata.external_url,
            '", '
        );
        json = string.concat(
            json,
            '"metalabel": { "node_registry_address": "',
            Strings.toHexString(uint256(uint160(address(nodeRegistry))), 20),
            '", "record_variant_name": "',
            metadata.metalabel_record_variant_name,
            '", "release_metadata_uri": "',
            metadata.metalabel_release_metadata_uri,
            '", "record_contents": ',
            contentsInnerJson,
            '}, "attributes": [',
            attributesInnerJson,
            "]}"
        );

        // Prepend base64 prefix + encode JSON
        tokenURI = string.concat(
            "data:application/json;base64,",
            Base64.encode(bytes(json))
        );
    }

    /// @notice Get the onchain metadata variant for a specific record
    /// @dev This is a view function that reads from SSTORE2 storage and picks
    /// the random or sequential variant, the full onchain metadata is
    /// generated in tokenURI
    function getStoredMetadataVariant(address collection, uint256 tokenId)
        public
        view
        returns (NFTMetadata memory metadata)
    {
        uint16 sequenceId = ICollection(collection).tokenSequenceId(tokenId);
        uint80 editionNumber = ICollection(collection).tokenMintData(tokenId);

        // Load all metadata variants from SSTORE2 storage
        NFTMetadata[] memory metadatas = abi.decode(
            SSTORE2.read(metadataStoragePointers[collection][sequenceId]),
            (NFTMetadata[])
        );

        // Metadata variants are default sequential, but can be pseudo-random
        // if the randomizeMetadataVariants flag is set.
        // Using (edition - 1) for sequential since edition number starts at 1
        uint256 idx = (editionNumber - 1) % metadatas.length;
        if (drops[collection][sequenceId].randomizeMetadataVariants) {
            idx =
                uint256(
                    keccak256(
                        abi.encodePacked(
                            collection,
                            sequenceId,
                            editionNumber,
                            tokenId
                        )
                    )
                ) %
                metadatas.length;
        }

        metadata = metadatas[idx];
    }

    /// @inheritdoc IEngine
    /// @dev Royalty bps and recipient is per-sequence.
    function getRoyaltyInfo(
        address collection,
        uint256 tokenId,
        uint256 salePrice
    ) external view override returns (address, uint256) {
        uint16 sequenceId = ICollection(collection).tokenSequenceId(tokenId);
        DropData storage drop = drops[collection][sequenceId];
        return (drop.revenueRecipient, (salePrice * drop.royaltyBps) / 10000);
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