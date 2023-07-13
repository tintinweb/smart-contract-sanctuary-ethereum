// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

///////////////////////////////////////////////////////////
// ░██████╗░█████╗░██████╗░██╗██████╗░████████╗██╗░░░██╗ //
// ██╔════╝██╔══██╗██╔══██╗██║██╔══██╗╚══██╔══╝╚██╗░██╔╝ //
// ╚█████╗░██║░░╚═╝██████╔╝██║██████╔╝░░░██║░░░░╚████╔╝░ //
// ░╚═══██╗██║░░██╗██╔══██╗██║██╔═══╝░░░░██║░░░░░╚██╔╝░░ //
// ██████╔╝╚█████╔╝██║░░██║██║██║░░░░░░░░██║░░░░░░██║░░░ //
// ╚═════╝░░╚════╝░╚═╝░░╚═╝╚═╝╚═╝░░░░░░░░╚═╝░░░░░░╚═╝░░░ //
///////////////////////////////////////////////////////////
//░░░░░░░░░░░░░░░░░░░░    STORAGE    ░░░░░░░░░░░░░░░░░░░░//
///////////////////////////////////////////////////////////

/**
  @title A generic data storage contract.
  @author @xtremetom
  @author @0xthedude

  Special thanks to @cxkoda, @frolic and @dhof
*/

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IContentStore} from "./dependencies/ethfs/IContentStore.sol";
import {AddressChunks} from "./utils/AddressChunks.sol";

import {IScriptyStorage} from "./interfaces/IScriptyStorage.sol";
import {IContractScript} from "./interfaces/IContractScript.sol";

contract ScriptyStorage is Ownable, IScriptyStorage, IContractScript {
    IContentStore public immutable contentStore;
    mapping(string => Script) public scripts;

    constructor(address _contentStoreAddress) {
        contentStore = IContentStore(_contentStoreAddress);
    }

    // =============================================================
    //                           MODIFIERS
    // =============================================================

    /**
     * @notice Check if the msg.sender is the owner of the script
     * @param name - Name given to the script. Eg: threejs.min.js_r148
     */
    modifier isScriptOwner(string calldata name) {
        if (msg.sender != scripts[name].owner) revert NotScriptOwner();
        _;
    }

    /**
     * @notice Check if a script can be created by checking if it already exists
     * @param name - Name given to the script. Eg: threejs.min.js_r148
     */
    modifier canCreate(string calldata name) {
        if (scripts[name].owner != address(0)) revert ScriptExists();
        _;
    }

    /**
     * @notice Check if a script is frozen
     * @param name - Name given to the script. Eg: threejs.min.js_r148
     */
    modifier isFrozen(string calldata name) {
        if (scripts[name].isFrozen) revert ScriptIsFrozen(name);
        _;
    }

    // =============================================================
    //                      MANAGEMENT OPERATIONS
    // =============================================================

    /**
     * @notice Create a new script
     * @param name - Name given to the script. Eg: threejs.min.js_r148
     * @param details - Any details the owner wishes to store about the script
     *
     * Emits an {ScriptCreated} event.
     */
    function createScript(string calldata name, bytes calldata details)
        public
        canCreate(name)
    {
        scripts[name] = Script(false, false, msg.sender, 0, details, new address[](0));
        emit ScriptCreated(name, details);
    }

    /**
     * @notice Add a code chunk to the script
     * @param name - Name given to the script. Eg: threejs.min.js_r148
     * @param chunk - Next sequential code chunk
     *
     * Emits an {ChunkStored} event.
     */
    function addChunkToScript(string calldata name, bytes calldata chunk)
        public
        isFrozen(name)
        isScriptOwner(name)
    {
        (, address pointer) = contentStore.addContent(chunk);
        scripts[name].chunks.push(pointer);
        scripts[name].size += chunk.length;
        emit ChunkStored(name, chunk.length);
    }

    /**
     * @notice Edit the script details
     * @param name - Name given to the script. Eg: threejs.min.js_r148
     * @param details - Any details the owner wishes to store about the script
     *
     * Emits an {ScriptDetailsUpdated} event.
     */
    function updateDetails(string calldata name, bytes calldata details)
        public
        isFrozen(name)
        isScriptOwner(name)
    {
        scripts[name].details = details;
        emit ScriptDetailsUpdated(name, details);
    }

    /**
     * @notice Update the verification status of the script
     * @param name - Name given to the script. Eg: threejs.min.js_r148
     * @param isVerified - The verification status
     *
     * Emits an {ScriptVerificationUpdated} event.
     */
    function updateScriptVerification(string calldata name, bool isVerified)
        public
        isFrozen(name)
        isScriptOwner(name)
    {
        scripts[name].isVerified = isVerified;
        emit ScriptVerificationUpdated(name, isVerified);
    }

    /**
     * @notice Update the frozen status of the script
     * @dev [WARNING] Once a script it frozen is can no longer be edited
     * @param name - Name given to the script. Eg: threejs.min.js_r148
     *
     * Emits an {ScriptFrozen} event.
     */
    function freezeScript(string calldata name)
        public
        isFrozen(name)
        isScriptOwner(name)
    {
        scripts[name].isFrozen = true;
        emit ScriptFrozen(name);
    }

    // =============================================================
    //                            GETTERS
    // =============================================================

    /**
     * @notice Get the full script
     * @param name - Name given to the script. Eg: threejs.min.js_r148
     * @param data - Arbitrary data. Not used by this contract.
     * @return script - Full script from merged chunks
     */
    function getScript(string memory name, bytes memory data)
        public
        view
        returns (bytes memory script)
    {
        return AddressChunks.mergeChunks(scripts[name].chunks);
    }

    /**
     * @notice Get script's chunk pointer list
     * @param name - Name given to the script. Eg: threejs.min.js_r148
     * @return pointers - List of pointers
     */
    function getScriptChunkPointers(string memory name)
        public
        view
        returns (address[] memory pointers)
    {
        return scripts[name].chunks;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * @title AddressChunks
 * @author @xtremetom
 * @notice Reads chunk pointers and merges their values
 */
library AddressChunks {
    function mergeChunks(address[] memory chunks)
        internal
        view
        returns (bytes memory o_code)
    {
        unchecked {
            assembly {
                let len := mload(chunks)
                let totalSize := 0x20
                let size := 0
                o_code := mload(0x40)

                // loop through all chunk addresses
                // - get address
                // - get data size
                // - get code and add to o_code
                // - update total size
                let targetChunk := 0
                for {
                    let i := 0
                } lt(i, len) {
                    i := add(i, 1)
                } {
                    targetChunk := mload(add(chunks, add(0x20, mul(i, 0x20))))
                    size := sub(extcodesize(targetChunk), 1)
                    extcodecopy(targetChunk, add(o_code, totalSize), 1, size)
                    totalSize := add(totalSize, size)
                }

                // update o_code size
                mstore(o_code, sub(totalSize, 0x20))
                // store o_code
                mstore(0x40, add(o_code, and(add(totalSize, 0x1f), not(0x1f))))
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

///////////////////////////////////////////////////////////
// ░██████╗░█████╗░██████╗░██╗██████╗░████████╗██╗░░░██╗ //
// ██╔════╝██╔══██╗██╔══██╗██║██╔══██╗╚══██╔══╝╚██╗░██╔╝ //
// ╚█████╗░██║░░╚═╝██████╔╝██║██████╔╝░░░██║░░░░╚████╔╝░ //
// ░╚═══██╗██║░░██╗██╔══██╗██║██╔═══╝░░░░██║░░░░░╚██╔╝░░ //
// ██████╔╝╚█████╔╝██║░░██║██║██║░░░░░░░░██║░░░░░░██║░░░ //
// ╚═════╝░░╚════╝░╚═╝░░╚═╝╚═╝╚═╝░░░░░░░░╚═╝░░░░░░╚═╝░░░ //
///////////////////////////////////////////////////////////

interface IContractScript {
    // =============================================================
    //                            GETTERS
    // =============================================================

    /**
     * @notice Get the full script
     * @param name - Name given to the script. Eg: threejs.min.js_r148
     * @param data - Arbitrary data to be passed to storage
     * @return script - Full script from merged chunks
     */
    function getScript(string calldata name, bytes memory data)
        external
        view
        returns (bytes memory script);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

///////////////////////////////////////////////////////////
// ░██████╗░█████╗░██████╗░██╗██████╗░████████╗██╗░░░██╗ //
// ██╔════╝██╔══██╗██╔══██╗██║██╔══██╗╚══██╔══╝╚██╗░██╔╝ //
// ╚█████╗░██║░░╚═╝██████╔╝██║██████╔╝░░░██║░░░░╚████╔╝░ //
// ░╚═══██╗██║░░██╗██╔══██╗██║██╔═══╝░░░░██║░░░░░╚██╔╝░░ //
// ██████╔╝╚█████╔╝██║░░██║██║██║░░░░░░░░██║░░░░░░██║░░░ //
// ╚═════╝░░╚════╝░╚═╝░░╚═╝╚═╝╚═╝░░░░░░░░╚═╝░░░░░░╚═╝░░░ //
///////////////////////////////////////////////////////////

interface IScriptyStorage {
    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct Script {
        bool isVerified;
        bool isFrozen;
        address owner;
        uint256 size;
        bytes details;
        address[] chunks;
    }

    // =============================================================
    //                            ERRORS
    // =============================================================

    /**
     * @notice Error for, The Script you are trying to create already exists
     */
    error ScriptExists();

    /**
     * @notice Error for, You dont have permissions to perform this action
     */
    error NotScriptOwner();

    /**
     * @notice Error for, The Script you are trying to edit is frozen
     */
    error ScriptIsFrozen(string name);

    // =============================================================
    //                            EVENTS
    // =============================================================

    /**
     * @notice Event for, Successful freezing of a script
     * @param name - Name given to the script. Eg: threejs.min.js_r148
     */
    event ScriptFrozen(string indexed name);

    /**
     * @notice Event for, Successful update of script verification status
     * @param name - Name given to the script. Eg: threejs.min.js_r148
     * @param isVerified - Verification status of the script
     */
    event ScriptVerificationUpdated(string indexed name, bool isVerified);

    /**
     * @notice Event for, Successful creation of a script
     * @param name - Name given to the script. Eg: threejs.min.js_r148
     * @param details - Custom details of the script
     */
    event ScriptCreated(string indexed name, bytes details);

    /**
     * @notice Event for, Successful addition of script chunk
     * @param name - Name given to the script. Eg: threejs.min.js_r148
     * @param size - Bytes size of the chunk
     */
    event ChunkStored(string indexed name, uint256 size);

    /**
     * @notice Event for, Successful update of custom details
     * @param name - Name given to the script. Eg: threejs.min.js_r148
     * @param details - Custom details of the script
     */
    event ScriptDetailsUpdated(string indexed name, bytes details);

    // =============================================================
    //                      MANAGEMENT OPERATIONS
    // =============================================================

    /**
     * @notice Create a new script
     * @param name - Name given to the script. Eg: threejs.min.js_r148
     * @param details - Any details the owner wishes to store about the script
     *
     * Emits an {ScriptCreated} event.
     */
    function createScript(string calldata name, bytes calldata details)
        external;

    /**
     * @notice Add a code chunk to the script
     * @param name - Name given to the script. Eg: threejs.min.js_r148
     * @param chunk - Next sequential code chunk
     *
     * Emits an {ChunkStored} event.
     */
    function addChunkToScript(string calldata name, bytes calldata chunk)
        external;

    /**
     * @notice Edit the script details
     * @param name - Name given to the script. Eg: threejs.min.js_r148
     * @param details - Any details the owner wishes to store about the script
     *
     * Emits an {ScriptDetailsUpdated} event.
     */
    function updateDetails(string calldata name, bytes calldata details)
        external;

    /**
     * @notice Update the verification status of the script
     * @param name - Name given to the script. Eg: threejs.min.js_r148
     * @param isVerified - The verification status
     *
     * Emits an {ScriptVerificationUpdated} event.
     */
    function updateScriptVerification(string calldata name, bool isVerified)
        external;
}

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