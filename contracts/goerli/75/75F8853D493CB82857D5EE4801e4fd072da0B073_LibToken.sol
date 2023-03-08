// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

struct Content {
    bytes32 checksum;
    address pointer;
}

struct File {
    uint256 size; // content length in bytes, max 24k
    Content[] contents;
}

function read(File memory file) view returns (string memory contents) {
    Content[] memory chunks = file.contents;

    // Adapted from https://gist.github.com/xtremetom/20411eb126aaf35f98c8a8ffa00123cd
    assembly {
        let len := mload(chunks)
        let totalSize := 0x20
        contents := mload(0x40)
        let size
        let chunk
        let pointer

        // loop through all pointer addresses
        // - get content
        // - get address
        // - get data size
        // - get code and add to contents
        // - update total size

        for { let i := 0 } lt(i, len) { i := add(i, 1) } {
            chunk := mload(add(chunks, add(0x20, mul(i, 0x20))))
            pointer := mload(add(chunk, 0x20))

            size := sub(extcodesize(pointer), 1)
            extcodecopy(pointer, add(contents, totalSize), 1, size)
            totalSize := add(totalSize, size)
        }

        // update contents size
        mstore(contents, sub(totalSize, 0x20))
        // store contents
        mstore(0x40, add(contents, and(add(totalSize, 0x1f), not(0x1f))))
    }
}

using {
    read
} for File global;

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

interface IContentStore {
    event NewChecksum(bytes32 indexed checksum, uint256 contentSize);

    error ChecksumExists(bytes32 checksum);
    error ChecksumNotFound(bytes32 checksum);

    function pointers(bytes32 checksum) external view returns (address pointer);

    function checksumExists(bytes32 checksum) external view returns (bool);

    function contentLength(bytes32 checksum)
        external
        view
        returns (uint256 size);

    function addPointer(address pointer) external returns (bytes32 checksum);

    function addContent(bytes memory content)
        external
        returns (bytes32 checksum, address pointer);

    function getPointer(bytes32 checksum)
        external
        view
        returns (address pointer);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import {File} from "./File.sol";
import {IContentStore} from "./IContentStore.sol";

interface IFileStore {
    event FileCreated(
        string indexed indexedFilename,
        bytes32 indexed checksum,
        string filename,
        uint256 size,
        bytes metadata
    );
    event FileDeleted(
        string indexed indexedFilename,
        bytes32 indexed checksum,
        string filename
    );

    error FileNotFound(string filename);
    error FilenameExists(string filename);
    error EmptyFile();

    function contentStore() external view returns (IContentStore);

    function files(string memory filename)
        external
        view
        returns (bytes32 checksum);

    function fileExists(string memory filename) external view returns (bool);

    function getChecksum(string memory filename)
        external
        view
        returns (bytes32 checksum);

    function getFile(string memory filename)
        external
        view
        returns (File memory file);

    function createFile(string memory filename, bytes32[] memory checksums)
        external
        returns (File memory file);

    function createFile(
        string memory filename,
        bytes32[] memory checksums,
        bytes memory extraData
    ) external returns (File memory file);

    function deleteFile(string memory filename) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface IFeeManager {
    function getWithdrawFeesBPS(
        address sender
    ) external view returns (address payable, uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

interface ITokenFactory {
    error InvalidUpgrade(address impl);
    error NotDeployed(address impl);

    /// @notice Creates a new token contract with the given implementation and data
    function create(
        address tokenImpl,
        bytes calldata data
    ) external returns (address clone);

    /// @notice checks if an implementation is valid
    function isValidDeployment(address impl) external view returns (bool);

    /// @notice registers a new implementation
    function registerDeployment(address impl) external;

    /// @notice unregisters an implementation
    function unregisterDeployment(address impl) external;

    /// @notice checks if an upgrade is valid
    function isValidUpgrade(
        address prevImpl,
        address newImpl
    ) external returns (bool);

    /// @notice registers a new upgrade
    function registerUpgrade(address prevImpl, address newImpl) external;

    /// @notice unregisters an upgrade
    function unregisterUpgrade(address prevImpl, address newImpl) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

import {Base64} from "base64-sol/base64.sol";
import {ITokenFactory} from "../interfaces/ITokenFactory.sol";
import {DynamicBuffer} from "../vendor/utils/DynamicBuffer.sol";
import {IFileStore} from "ethfs/IFileStore.sol";
import {File} from "ethfs/File.sol";

library LibHTMLRenderer {
    error InvalidScriptType();

    enum ScriptType {
        JAVASCRIPT_PLAINTEXT,
        JAVASCRIPT_BASE64,
        JAVASCRIPT_URL_ENCODED,
        JAVASCRIPT_GZIP,
        CUSTOM
    }

    struct ScriptRequest {
        ScriptType scriptType;
        string name;
        bytes data;
        bytes urlEncodedPrefix;
        bytes urlEncodedSuffix;
    }

    // [[[ Single url encoded tags ]]]

    //data:text/html,
    bytes public constant HTML_TAG_URL_SAFE = "data%3Atext%2Fhtml%2C";

    // [[[ Double url encoded tags ]]]

    //<body><style type="text/css">html{height:100%}body{min-height:100%;margin:0;padding:0}canvas{padding:0;margin:auto;display:block;position:absolute;top:0;bottom:0;left:0;right:0}</style>
    bytes constant HTML_START =
        "%253Cbody%253E%253Cstyle%2520type=%2522text/css%2522%253Ehtml%257Bheight:100%2525%257Dbody%257Bmin-height:100%2525;margin:0;padding:0%257Dcanvas%257Bpadding:0;margin:auto;display:block;position:absolute;top:0;bottom:0;left:0;right:0%257D%253C/style%253E";

    //</body>
    bytes constant HTML_END = "%253C/body%253E";

    //<script>
    bytes constant SCRIPT_OPEN_PLAINTEXT = "%253Cscript%253E";

    //<script src="data:text/javascript;base64,
    bytes constant SCRIPT_OPEN_BASE64 =
        "%253Cscript%2520src=%2522data:text/javascript;base64,";

    //<script type="text/javascript+gzip" src="data:text/javascript;base64,
    bytes constant SCRIPT_OPEN_GZIP =
        "%253Cscript%2520type=%2522text/javascript+gzip%2522%2520src=%2522data:text/javascript;base64,";

    //</script>
    bytes constant SCRIPT_CLOSE_PLAINTEXT = "%253C/script%253E";

    //"></script>
    bytes constant SCRIPT_CLOSE_WITH_END_TAG = "%2522%253E%253C/script%253E";

    uint256 constant HTML_TOTAL_BYTES = 376;

    uint256 constant SCRIPT_BASE64_BYTES = 80;

    uint256 constant SCRIPT_GZIP_BYTES = 120;

    uint256 constant SCRIPT_PLAINTEXT_BYTES = 33;

    // [[[ HTML Generation Functions ]]]

    /**
     * @notice Construct url safe html from the given scripts.
     */
    function generateDoubleURLEncodedHTML(
        ScriptRequest[] calldata scripts,
        address ethFS
    ) external view returns (bytes memory) {
        uint256 i = 0;
        uint256 length = scripts.length;
        bytes[] memory scriptData = new bytes[](length);
        uint256 bufferSize = HTML_TOTAL_BYTES;

        unchecked {
            do {
                scriptData[i] = getScriptData(scripts[i], ethFS);
                bufferSize +=
                    (
                        scripts[i].scriptType == ScriptType.JAVASCRIPT_PLAINTEXT
                            ? sizeForBase64Encoding(scriptData[i].length)
                            : scriptData[i].length
                    ) +
                    getScriptSize(scripts[i]);
            } while (++i < length);
        }

        bytes memory buffer = DynamicBuffer.allocate(bufferSize);

        DynamicBuffer.appendSafe(buffer, HTML_TAG_URL_SAFE);
        DynamicBuffer.appendSafe(buffer, HTML_START);
        appendScripts(buffer, scripts, scriptData, ethFS);
        DynamicBuffer.appendSafe(buffer, HTML_END);

        return buffer;
    }

    function appendScripts(
        bytes memory buffer,
        ScriptRequest[] calldata scripts,
        bytes[] memory scriptData,
        address ethfs
    ) internal view {
        bytes memory prefix;
        bytes memory suffix;
        uint256 i;
        uint256 length = scripts.length;

        unchecked {
            do {
                (prefix, suffix) = getScriptPrefixAndSuffix(scripts[i]);
                DynamicBuffer.appendSafe(buffer, prefix);
                if (scripts[i].scriptType == ScriptType.JAVASCRIPT_PLAINTEXT)
                    DynamicBuffer.appendSafeBase64(
                        buffer,
                        scriptData[i],
                        false,
                        false
                    );
                else
                    DynamicBuffer.appendSafe(
                        buffer,
                        getScriptData(scripts[i], ethfs)
                    );
                DynamicBuffer.appendSafe(buffer, suffix);
            } while (++i < length);
        }
    }

    function getScriptData(
        ScriptRequest calldata script,
        address ethFS
    ) internal view returns (bytes memory) {
        return
            script.data.length > 0
                ? script.data
                : bytes(IFileStore(ethFS).getFile(script.name).read());
    }

    function getScriptSize(
        ScriptRequest calldata script
    ) public pure returns (uint256) {
        if (
            script.urlEncodedPrefix.length > 0 &&
            script.urlEncodedSuffix.length > 0
        )
            return
                script.urlEncodedPrefix.length + script.urlEncodedSuffix.length;
        else if (script.scriptType <= ScriptType.JAVASCRIPT_BASE64)
            return SCRIPT_BASE64_BYTES;
        else if (script.scriptType == ScriptType.JAVASCRIPT_URL_ENCODED)
            return SCRIPT_PLAINTEXT_BYTES;
        else if (script.scriptType == ScriptType.JAVASCRIPT_GZIP)
            return SCRIPT_GZIP_BYTES;
        else revert InvalidScriptType();
    }

    function getScriptPrefixAndSuffix(
        ScriptRequest calldata script
    ) internal pure returns (bytes memory, bytes memory) {
        if (
            script.urlEncodedPrefix.length > 0 &&
            script.urlEncodedSuffix.length > 0
        ) return (script.urlEncodedPrefix, script.urlEncodedSuffix);
        else if (script.scriptType <= ScriptType.JAVASCRIPT_BASE64)
            return (SCRIPT_OPEN_BASE64, SCRIPT_CLOSE_WITH_END_TAG);
        else if (script.scriptType == ScriptType.JAVASCRIPT_URL_ENCODED)
            return (SCRIPT_OPEN_PLAINTEXT, SCRIPT_CLOSE_PLAINTEXT);
        else if (script.scriptType == ScriptType.JAVASCRIPT_GZIP)
            return (SCRIPT_OPEN_GZIP, SCRIPT_CLOSE_WITH_END_TAG);
        else revert InvalidScriptType();
    }

    function sizeForBase64Encoding(
        uint256 value
    ) internal pure returns (uint256) {
        unchecked {
            return 4 * ((value + 2) / 3);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

import {LibHTMLRenderer} from "./LibHTMLRenderer.sol";

struct TokenStorage {
    mapping(uint256 => uint256) tokenIdToBlockDifficulty;
    mapping(address => bool) allowedMinters;
    address factory;
    address o11y;
    address feeManager;
    address ethFS;
    address fundsRecipent;
    address interactor;
    bool artistProofsMinted;
    uint256 maxSupply;
}

struct MetadataStorage {
    LibHTMLRenderer.ScriptRequest[] imports;
    string symbol;
    string urlEncodedName;
    string urlEncodedDescription;
    string urlEncodedPreviewBaseURI;
    address scriptPointer;
}

struct FixedPriceSaleInfo {
    mapping(address => uint256) presaleMintsByAddress;
    uint64 publicStartTime;
    uint64 publicEndTime;
    uint64 presaleStartTime;
    uint64 presaleEndTime;
    uint112 publicPrice;
    uint112 presalePrice;
    uint64 maxPresaleMintsPerAddress;
    bytes32 merkleRoot;
}

library LibStorage {
    bytes32 constant TOKEN_STORAGE_POSITION =
        keccak256("persistence.storage.token");
    bytes32 constant METADATA_STORAGE_POSITION =
        keccak256("persistence.storage.metadata");
    bytes32 constant FIXED_PRICE_SALE_STORAGE_POSITION =
        keccak256("persistence.storage.fixedPriceSale");

    function tokenStorage() internal pure returns (TokenStorage storage ts) {
        bytes32 position = TOKEN_STORAGE_POSITION;
        assembly {
            ts.slot := position
        }
    }

    function metadataStorage()
        internal
        pure
        returns (MetadataStorage storage ms)
    {
        bytes32 position = METADATA_STORAGE_POSITION;
        assembly {
            ms.slot := position
        }
    }

    function fixedPriceSaleInfo()
        internal
        pure
        returns (FixedPriceSaleInfo storage fps)
    {
        bytes32 position = FIXED_PRICE_SALE_STORAGE_POSITION;
        assembly {
            fps.slot := position
        }
    }
}

contract WithStorage {
    function ts() internal pure returns (TokenStorage storage) {
        return LibStorage.tokenStorage();
    }

    function ms() internal pure returns (MetadataStorage storage) {
        return LibStorage.metadataStorage();
    }

    function fixedPriceSaleInfo()
        internal
        pure
        returns (FixedPriceSaleInfo storage)
    {
        return LibStorage.fixedPriceSaleInfo();
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

import {LibStorage, TokenStorage} from "./LibStorage.sol";
import {IToken} from "../tokens/interfaces/IToken.sol";
import {IFeeManager} from "../interfaces/IFeeManager.sol";
import {IObservability} from "../observability/interface/IObservability.sol";

library LibToken {
    function ts() internal pure returns (TokenStorage storage) {
        return LibStorage.tokenStorage();
    }

    function feeForAmount(
        uint256 amount
    ) public view returns (address payable, uint256) {
        (address payable recipient, uint256 bps) = IFeeManager(ts().feeManager)
            .getWithdrawFeesBPS(address(this));
        return (recipient, (amount * bps) / 10_000);
    }

    /// @notice withdraws the funds from the contract
    function withdraw() external returns (bool) {
        uint256 FUNDS_SEND_GAS_LIMIT = 210_000;
        uint256 amount = address(this).balance;

        (address payable feeRecipent, uint256 protocolFee) = feeForAmount(
            amount
        );

        // Pay protocol fee
        if (protocolFee > 0) {
            (bool successFee, ) = feeRecipent.call{
                value: protocolFee,
                gas: FUNDS_SEND_GAS_LIMIT
            }("");

            if (!successFee) revert IToken.FundsSendFailure();
            amount -= protocolFee;
        }

        (bool successFunds, ) = ts().fundsRecipent.call{
            value: amount,
            gas: FUNDS_SEND_GAS_LIMIT
        }("");

        if (!successFunds) revert IToken.FundsSendFailure();

        IObservability(ts().o11y).emitFundsWithdrawn(
            msg.sender,
            ts().fundsRecipent,
            amount
        );
        return successFunds;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.16;

interface IObservabilityEvents {
    /// @notice Emitted when a new clone is deployed
    event CloneDeployed(
        address indexed factory,
        address indexed owner,
        address clone
    );

    /// @notice Emitted when a sale has occured
    event Sale(
        address indexed clone,
        address indexed to,
        uint256 pricePerToken,
        uint256 amount
    );

    /// @notice Emitted when funds have been withdrawn
    event FundsWithdrawn(
        address indexed clone,
        address indexed withdrawnBy,
        address indexed withdrawnTo,
        uint256 amount
    );

    /// @notice Emitted when a new implementation is registered
    event DeploymentTargetRegistered(address indexed impl);

    /// @notice Emitted when an implementation is unregistered
    event DeploymentTargetUnregistered(address indexed impl);

    /// @notice Emitted when an upgrade is registered
    /// @param prevImpl The address of the previous implementation
    /// @param newImpl The address of the registered upgrade
    event UpgradeRegistered(address indexed prevImpl, address indexed newImpl);

    /// @notice Emitted when an upgrade is unregistered
    /// @param prevImpl The address of the previous implementation
    /// @param newImpl The address of the unregistered upgrade
    event UpgradeUnregistered(
        address indexed prevImpl,
        address indexed newImpl
    );
}

interface IObservability {
    function emitCloneDeployed(address owner, address clone) external;

    function emitSale(
        address to,
        uint256 pricePerToken,
        uint256 amount
    ) external;

    function emitFundsWithdrawn(
        address withdrawnBy,
        address withdrawnTo,
        uint256 amount
    ) external;

    function emitDeploymentTargetRegistererd(address impl) external;

    function emitDeploymentTargetUnregistered(address imp) external;

    function emitUpgradeRegistered(address prevImpl, address impl) external;

    function emitUpgradeUnregistered(address prevImpl, address impl) external;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {LibHTMLRenderer} from "../../libraries/LibHTMLRenderer.sol";

interface IToken {
    struct TokenInfo {
        address factory;
        address o11y;
        address feeManager;
        address fundsRecipent;
        address interactor;
        bool artistProofsMinted;
        uint256 maxSupply;
    }

    struct MetadataInfo {
        string symbol;
        string urlEncodedName;
        string urlEncodedDescription;
        string urlEncodedPreviewBaseURI;
        address scriptPointer;
        LibHTMLRenderer.ScriptRequest[] imports;
    }

    error FactoryMustInitilize();
    error SenderNotMinter();
    error FundsSendFailure();
    error MaxSupplyReached();
    error ProofsMinted();

    /// @notice returns the total supply of tokens
    function totalSupply() external view returns (uint256);

    function tokenInfo() external view returns (TokenInfo memory info);

    function metadataInfo() external view returns (MetadataInfo memory info);

    /// @notice withdraws the funds from the contract
    function withdraw() external returns (bool);

    /// @notice mint a token for the given address
    function safeMint(address to) external;

    /// @notice sets the funds recipent for token funds
    function setFundsRecipent(address fundsRecipent) external;

    /// @notice sets the minter status for the given user
    function setMinter(address user, bool isAllowed) external;
}

// SPDX-License-Identifier: MIT
// Copyright (c) 2021 the ethier authors (github.com/divergencetech/ethier)

pragma solidity >=0.8.0;

/// @title DynamicBuffer
/// @author David Huber (@cxkoda) and Simon Fremaux (@dievardump). See also
///         https://raw.githubusercontent.com/dievardump/solidity-dynamic-buffer
/// @notice This library is used to allocate a big amount of container memory
//          which will be subsequently filled without needing to reallocate
///         memory.
/// @dev First, allocate memory.
///      Then use `buffer.appendUnchecked(theBytes)` or `appendSafe()` if
///      bounds checking is required.
library DynamicBuffer {
    /// @notice Allocates container space for the DynamicBuffer
    /// @param capacity_ The intended max amount of bytes in the buffer
    /// @return buffer The memory location of the buffer
    /// @dev Allocates `capacity_ + 0x60` bytes of space
    ///      The buffer array starts at the first container data position,
    ///      (i.e. `buffer = container + 0x20`)
    function allocate(
        uint256 capacity_
    ) internal pure returns (bytes memory buffer) {
        assembly {
            // Get next-free memory address
            let container := mload(0x40)

            // Allocate memory by setting a new next-free address
            {
                // Add 2 x 32 bytes in size for the two length fields
                // Add 32 bytes safety space for 32B chunked copy
                let size := add(capacity_, 0x60)
                let newNextFree := add(container, size)
                mstore(0x40, newNextFree)
            }

            // Set the correct container length
            {
                let length := add(capacity_, 0x40)
                mstore(container, length)
            }

            // The buffer starts at idx 1 in the container (0 is length)
            buffer := add(container, 0x20)

            // Init content with length 0
            mstore(buffer, 0)
        }

        return buffer;
    }

    /// @notice Appends data to buffer, and update buffer length
    /// @param buffer the buffer to append the data to
    /// @param data the data to append
    /// @dev Does not perform out-of-bound checks (container capacity)
    ///      for efficiency.
    function appendUnchecked(
        bytes memory buffer,
        bytes memory data
    ) internal pure {
        assembly {
            let length := mload(data)
            for {
                data := add(data, 0x20)
                let dataEnd := add(data, length)
                let copyTo := add(buffer, add(mload(buffer), 0x20))
            } lt(data, dataEnd) {
                data := add(data, 0x20)
                copyTo := add(copyTo, 0x20)
            } {
                // Copy 32B chunks from data to buffer.
                // This may read over data array boundaries and copy invalid
                // bytes, which doesn't matter in the end since we will
                // later set the correct buffer length, and have allocated an
                // additional word to avoid buffer overflow.
                mstore(copyTo, mload(data))
            }

            // Update buffer length
            mstore(buffer, add(mload(buffer), length))
        }
    }

    /// @notice Appends data to buffer, and update buffer length
    /// @param buffer the buffer to append the data to
    /// @param data the data to append
    /// @dev Performs out-of-bound checks and calls `appendUnchecked`.
    function appendSafe(bytes memory buffer, bytes memory data) internal pure {
        checkOverflow(buffer, data.length);
        appendUnchecked(buffer, data);
    }

    /// @notice Appends data encoded as Base64 to buffer.
    /// @param fileSafe  Whether to replace '+' with '-' and '/' with '_'.
    /// @param noPadding Whether to strip away the padding.
    /// @dev Encodes `data` using the base64 encoding described in RFC 4648.
    /// See: https://datatracker.ietf.org/doc/html/rfc4648
    /// Author: Modified from Solady (https://github.com/vectorized/solady/blob/main/src/utils/Base64.sol)
    /// Author: Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/Base64.sol)
    /// Author: Modified from (https://github.com/Brechtpd/base64/blob/main/base64.sol) by Brecht Devos.
    function appendSafeBase64(
        bytes memory buffer,
        bytes memory data,
        bool fileSafe,
        bool noPadding
    ) internal pure {
        uint256 dataLength = data.length;

        if (data.length == 0) {
            return;
        }

        uint256 encodedLength;
        uint256 r;
        assembly {
            // For each 3 bytes block, we will have 4 bytes in the base64
            // encoding: `encodedLength = 4 * divCeil(dataLength, 3)`.
            // The `shl(2, ...)` is equivalent to multiplying by 4.
            encodedLength := shl(2, div(add(dataLength, 2), 3))

            r := mod(dataLength, 3)
            if noPadding {
                // if r == 0 => no modification
                // if r == 1 => encodedLength -= 2
                // if r == 2 => encodedLength -= 1
                encodedLength := sub(
                    encodedLength,
                    add(iszero(iszero(r)), eq(r, 1))
                )
            }
        }

        checkOverflow(buffer, encodedLength);

        assembly {
            let nextFree := mload(0x40)

            // Store the table into the scratch space.
            // Offsetted by -1 byte so that the `mload` will load the character.
            // We will rewrite the free memory pointer at `0x40` later with
            // the allocated size.
            mstore(0x1f, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdef")
            mstore(
                0x3f,
                sub(
                    "ghijklmnopqrstuvwxyz0123456789-_",
                    // The magic constant 0x0230 will translate "-_" + "+/".
                    mul(iszero(fileSafe), 0x0230)
                )
            )

            // Skip the first slot, which stores the length.
            let ptr := add(add(buffer, 0x20), mload(buffer))
            let end := add(data, dataLength)

            // Run over the input, 3 bytes at a time.
            // prettier-ignore
            // solhint-disable-next-line no-empty-blocks
            for {} 1 {} {
                    data := add(data, 3) // Advance 3 bytes.
                    let input := mload(data)

                    // Write 4 bytes. Optimized for fewer stack operations.
                    mstore8(    ptr    , mload(and(shr(18, input), 0x3F)))
                    mstore8(add(ptr, 1), mload(and(shr(12, input), 0x3F)))
                    mstore8(add(ptr, 2), mload(and(shr( 6, input), 0x3F)))
                    mstore8(add(ptr, 3), mload(and(        input , 0x3F)))
                    
                    ptr := add(ptr, 4) // Advance 4 bytes.
                    // prettier-ignore
                    if iszero(lt(data, end)) { break }
                }

            if iszero(noPadding) {
                // Offset `ptr` and pad with '='. We can simply write over the end.
                mstore8(sub(ptr, iszero(iszero(r))), 0x3d) // Pad at `ptr - 1` if `r > 0`.
                mstore8(sub(ptr, shl(1, eq(r, 1))), 0x3d) // Pad at `ptr - 2` if `r == 1`.
            }

            mstore(buffer, add(mload(buffer), encodedLength))
            mstore(0x40, nextFree)
        }
    }

    /// @notice Appends data encoded as Base64 to buffer.
    /// @param fileSafe  Whether to replace '+' with '-' and '/' with '_'.
    /// @param noPadding Whether to strip away the padding.
    /// @dev Encodes `data` using the base64 encoding described in RFC 4648.
    /// See: https://datatracker.ietf.org/doc/html/rfc4648
    /// Author: Modified from Solady (https://github.com/vectorized/solady/blob/main/src/utils/Base64.sol)
    /// Author: Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/Base64.sol)
    /// Author: Modified from (https://github.com/Brechtpd/base64/blob/main/base64.sol) by Brecht Devos.
    function appendUncheckedBase64(
        bytes memory buffer,
        bytes memory data,
        bool fileSafe,
        bool noPadding
    ) internal pure {
        uint256 dataLength = data.length;

        if (data.length == 0) {
            return;
        }

        uint256 encodedLength;
        uint256 r;
        assembly {
            // For each 3 bytes block, we will have 4 bytes in the base64
            // encoding: `encodedLength = 4 * divCeil(dataLength, 3)`.
            // The `shl(2, ...)` is equivalent to multiplying by 4.
            encodedLength := shl(2, div(add(dataLength, 2), 3))

            r := mod(dataLength, 3)
            if noPadding {
                // if r == 0 => no modification
                // if r == 1 => encodedLength -= 2
                // if r == 2 => encodedLength -= 1
                encodedLength := sub(
                    encodedLength,
                    add(iszero(iszero(r)), eq(r, 1))
                )
            }
        }

        assembly {
            let nextFree := mload(0x40)

            // Store the table into the scratch space.
            // Offsetted by -1 byte so that the `mload` will load the character.
            // We will rewrite the free memory pointer at `0x40` later with
            // the allocated size.
            mstore(0x1f, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdef")
            mstore(
                0x3f,
                sub(
                    "ghijklmnopqrstuvwxyz0123456789-_",
                    // The magic constant 0x0230 will translate "-_" + "+/".
                    mul(iszero(fileSafe), 0x0230)
                )
            )

            // Skip the first slot, which stores the length.
            let ptr := add(add(buffer, 0x20), mload(buffer))
            let end := add(data, dataLength)

            // Run over the input, 3 bytes at a time.
            // prettier-ignore
            // solhint-disable-next-line no-empty-blocks
            for {} 1 {} {
                    data := add(data, 3) // Advance 3 bytes.
                    let input := mload(data)

                    // Write 4 bytes. Optimized for fewer stack operations.
                    mstore8(    ptr    , mload(and(shr(18, input), 0x3F)))
                    mstore8(add(ptr, 1), mload(and(shr(12, input), 0x3F)))
                    mstore8(add(ptr, 2), mload(and(shr( 6, input), 0x3F)))
                    mstore8(add(ptr, 3), mload(and(        input , 0x3F)))
                    
                    ptr := add(ptr, 4) // Advance 4 bytes.
                    // prettier-ignore
                    if iszero(lt(data, end)) { break }
                }

            if iszero(noPadding) {
                // Offset `ptr` and pad with '='. We can simply write over the end.
                mstore8(sub(ptr, iszero(iszero(r))), 0x3d) // Pad at `ptr - 1` if `r > 0`.
                mstore8(sub(ptr, shl(1, eq(r, 1))), 0x3d) // Pad at `ptr - 2` if `r == 1`.
            }

            mstore(buffer, add(mload(buffer), encodedLength))
            mstore(0x40, nextFree)
        }
    }

    /// @notice Returns the capacity of a given buffer.
    function capacity(bytes memory buffer) internal pure returns (uint256) {
        uint256 cap;
        assembly {
            cap := sub(mload(sub(buffer, 0x20)), 0x40)
        }
        return cap;
    }

    /// @notice Reverts if the buffer will overflow after appending a given
    /// number of bytes.
    function checkOverflow(
        bytes memory buffer,
        uint256 addedLength
    ) internal pure {
        uint256 cap = capacity(buffer);
        uint256 newLength = buffer.length + addedLength;
        if (cap < newLength) {
            revert("DynamicBuffer: Appending out of bounds.");
        }
    }
}