// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() external {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
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
pragma solidity ^0.8.4;

/// @notice Read and write to persistent storage at a fraction of the cost.
/// @author Solady (https://github.com/vectorized/solmady/blob/main/src/utils/SSTORE2.sol)
/// @author Saw-mon-and-Natalie (https://github.com/Saw-mon-and-Natalie)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SSTORE2.sol)
/// @author Modified from 0xSequence (https://github.com/0xSequence/sstore2/blob/master/contracts/SSTORE2.sol)
library SSTORE2 {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        CUSTOM ERRORS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    error DeploymentFailed();

    error InvalidPointer();

    error ReadOutOfBounds();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         WRITE LOGIC                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function write(bytes memory data) internal returns (address pointer) {
        // Note: The assembly block below does not expand the memory.
        assembly {
            let originalDataLength := mload(data)

            // Add 1 to data size since we are prefixing it with a STOP opcode.
            let dataSize := add(originalDataLength, 1)

            /**
             * ------------------------------------------------------------------------------+
             * Opcode      | Mnemonic        | Stack                   | Memory              |
             * ------------------------------------------------------------------------------|
             * 61 codeSize | PUSH2 codeSize  | codeSize                |                     |
             * 80          | DUP1            | codeSize codeSize       |                     |
             * 60 0xa      | PUSH1 0xa       | 0xa codeSize codeSize   |                     |
             * 3D          | RETURNDATASIZE  | 0 0xa codeSize codeSize |                     |
             * 39          | CODECOPY        | codeSize                | [0..codeSize): code |
             * 3D          | RETURNDATASZIE  | 0 codeSize              | [0..codeSize): code |
             * F3          | RETURN          |                         | [0..codeSize): code |
             * 00          | STOP            |                         |                     |
             * ------------------------------------------------------------------------------+
             * @dev Prefix the bytecode with a STOP opcode to ensure it cannot be called.
             * Also PUSH2 is used since max contract size cap is 24,576 bytes which is less than 2 ** 16.
             */
            mstore(
                data,
                or(
                    0x61000080600a3d393df300,
                    // Left shift `dataSize` by 64 so that it lines up with the 0000 after PUSH2.
                    shl(0x40, dataSize)
                )
            )

            // Deploy a new contract with the generated creation code.
            pointer := create(0, add(data, 0x15), add(dataSize, 0xa))

            // If `pointer` is zero, revert.
            if iszero(pointer) {
                // Store the function selector of `DeploymentFailed()`.
                mstore(0x00, 0x30116425)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // Restore original length of the variable size `data`.
            mstore(data, originalDataLength)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         READ LOGIC                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    function read(address pointer) internal view returns (bytes memory data) {
        assembly {
            let pointerCodesize := extcodesize(pointer)
            if iszero(pointerCodesize) {
                // Store the function selector of `InvalidPointer()`.
                mstore(0x00, 0x11052bb4)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Offset all indices by 1 to skip the STOP opcode.
            let size := sub(pointerCodesize, 1)

            // Get the pointer to the free memory and allocate
            // enough 32-byte words for the data and the length of the data,
            // then copy the code to the allocated memory.
            // Masking with 0xffe0 will suffice, since contract size is less than 16 bits.
            data := mload(0x40)
            mstore(0x40, add(data, and(add(size, 0x3f), 0xffe0)))
            mstore(data, size)
            extcodecopy(pointer, add(data, 0x20), 1, size)
        }
    }

    function read(address pointer, uint256 start) internal view returns (bytes memory data) {
        assembly {
            let pointerCodesize := extcodesize(pointer)
            if iszero(pointerCodesize) {
                // Store the function selector of `InvalidPointer()`.
                mstore(0x00, 0x11052bb4)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // If `!(pointer.code.size > start)`, reverts.
            // This also handles the case where `start + 1` overflows.
            if iszero(gt(pointerCodesize, start)) {
                // Store the function selector of `ReadOutOfBounds()`.
                mstore(0x00, 0x84eb0dd1)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            let size := sub(pointerCodesize, add(start, 1))

            // Get the pointer to the free memory and allocate
            // enough 32-byte words for the data and the length of the data,
            // then copy the code to the allocated memory.
            // Masking with 0xffe0 will suffice, since contract size is less than 16 bits.
            data := mload(0x40)
            mstore(0x40, add(data, and(add(size, 0x3f), 0xffe0)))
            mstore(data, size)
            extcodecopy(pointer, add(data, 0x20), add(start, 1), size)
        }
    }

    function read(
        address pointer,
        uint256 start,
        uint256 end
    ) internal view returns (bytes memory data) {
        assembly {
            let pointerCodesize := extcodesize(pointer)
            if iszero(pointerCodesize) {
                // Store the function selector of `InvalidPointer()`.
                mstore(0x00, 0x11052bb4)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // If `!(pointer.code.size > end) || (start > end)`, revert.
            // This also handles the cases where `end + 1` or `start + 1` overflow.
            if iszero(
                and(
                    gt(pointerCodesize, end), // Within bounds.
                    iszero(gt(start, end)) // Valid range.
                )
            ) {
                // Store the function selector of `ReadOutOfBounds()`.
                mstore(0x00, 0x84eb0dd1)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            let size := sub(end, start)

            // Get the pointer to the free memory and allocate
            // enough 32-byte words for the data and the length of the data,
            // then copy the code to the allocated memory.
            // Masking with 0xffe0 will suffice, since contract size is less than 16 bits.
            data := mload(0x40)
            mstore(0x40, add(data, and(add(size, 0x3f), 0xffe0)))
            mstore(data, size)
            extcodecopy(pointer, add(data, 0x20), add(start, 1), size)
        }
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

import {SSTORE2} from "solady/utils/SSTORE2.sol";
import {IFileStore} from "./IFileStore.sol";
import {Ownable2Step} from "openzeppelin/access/Ownable2Step.sol";
import {File, Content} from "./File.sol";
import {IContentStore} from "./IContentStore.sol";

contract FileStore is IFileStore, Ownable2Step {
    IContentStore public immutable contentStore;

    // filename => File checksum
    mapping(string => bytes32) public files;

    constructor(IContentStore _contentStore) {
        contentStore = _contentStore;
    }

    function fileExists(string memory filename) public view returns (bool) {
        return files[filename] != bytes32(0);
    }

    function getChecksum(string memory filename)
        public
        view
        returns (bytes32 checksum)
    {
        checksum = files[filename];
        if (checksum == bytes32(0)) {
            revert FileNotFound(filename);
        }
        return checksum;
    }

    function getFile(string memory filename)
        public
        view
        returns (File memory file)
    {
        bytes32 checksum = files[filename];
        if (checksum == bytes32(0)) {
            revert FileNotFound(filename);
        }
        address pointer = contentStore.pointers(checksum);
        if (pointer == address(0)) {
            revert FileNotFound(filename);
        }
        return abi.decode(SSTORE2.read(pointer), (File));
    }

    function createFile(string memory filename, bytes32[] memory checksums)
        public
        returns (File memory file)
    {
        return createFile(filename, checksums, new bytes(0));
    }

    function createFile(
        string memory filename,
        bytes32[] memory checksums,
        bytes memory extraData
    ) public returns (File memory file) {
        if (files[filename] != bytes32(0)) {
            revert FilenameExists(filename);
        }
        return _createFile(filename, checksums, extraData);
    }

    function _createFile(
        string memory filename,
        bytes32[] memory checksums,
        bytes memory extraData
    ) private returns (File memory file) {
        Content[] memory contents = new Content[](checksums.length);
        uint256 size = 0;
        // TODO: optimize this
        for (uint256 i = 0; i < checksums.length; ++i) {
            size += contentStore.contentLength(checksums[i]);
            contents[i] = Content({
                checksum: checksums[i],
                pointer: contentStore.getPointer(checksums[i])
            });
        }
        if (size == 0) {
            revert EmptyFile();
        }
        file = File({size: size, contents: contents});
        (bytes32 checksum, ) = contentStore.addContent(abi.encode(file));
        files[filename] = checksum;
        emit FileCreated(filename, checksum, filename, file.size, extraData);
    }

    function deleteFile(string memory filename) public onlyOwner {
        bytes32 checksum = files[filename];
        if (checksum == bytes32(0)) {
            revert FileNotFound(filename);
        }
        delete files[filename];
        emit FileDeleted(filename, checksum, filename);
    }
}

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