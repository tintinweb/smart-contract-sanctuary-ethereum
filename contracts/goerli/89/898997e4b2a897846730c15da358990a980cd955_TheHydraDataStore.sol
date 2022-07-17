// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./interfaces/ITheHydraDataStore.sol";
import "solmate/auth/Owned.sol";
import "solmate/utils/SSTORE2.sol";

/// @title TheHydra is the genesis collection of the Altered Earth NFT series. 
/// @author therightchoyce.eth
/// @notice This contract acts as an on-chain data store for various pieces of the artwork
/// @dev Uses SSTORE2 to get/set raw data on-chain
contract TheHydraDataStore is ITheHydraDataStore, Owned {

    // --------------------------------------------------------
    // ~~ Internal storage  ~~
    // --------------------------------------------------------

    /// @dev Uri for off chain storage.. i.e. an IPFS link -- This is private since we need to expose the function in the interface in order to allow for cross-contract interaction
    string private offChainBaseURI;
    
    /// @dev Byte size of each on-chain photo
    uint256 private constant photoDataByteSize = 5128;

    /// @dev Maps each photo to its on-chain storage address
    mapping(uint256 => address) private onChainStorage;

    // --------------------------------------------------------
    // ~~ Errors ~~
    // --------------------------------------------------------

    error BeyondTheScopeOfConsciousness();
    error InvalidMemorySequence();

    // --------------------------------------------------------
    // ~~ Constructor Logic ~~
    // --------------------------------------------------------

    /// @param _owner The owner of the contract, when deployed
    /// @param _offChainBaseURI The base url for any assets in this collection, i.e. an IPFS link
    constructor(
        address _owner,
        string memory _offChainBaseURI
    ) Owned(_owner) {
        offChainBaseURI = _offChainBaseURI;
    }

    // --------------------------------------------------------
    // ~~ Off Chain Storage I.E BaseURI logic ~~
    // --------------------------------------------------------

    /// @notice Admin function to set the baseURI for off-chain photos, i.e. an IPFS link
    /// @param _baseURI The new baseURI to set
    function setOffChainBaseURI(
        string memory _baseURI
    ) external onlyOwner {
        offChainBaseURI = _baseURI;
    }

    /// @notice Retrieve the currently set offChainBaseURI
    /// @dev Used by the metadata contract to construct the tokenURI
    function getOffChainBaseURI() external view returns (string memory) {
        return offChainBaseURI;
    }

    // --------------------------------------------------------
    // ~~ On Chain Storage ~~
    // --------------------------------------------------------

    /// @notice Admin function to store the on-chain data for a particular photo
    /// @dev Uses SSTORE2 to store bytes data as a stand-alone contract
    /// @param _photoId The id of the photo -- TODO: This may have to change!
    /// @param _data The raw data in the .xqst formar
    function storePhotoData(
        uint256 _photoId,
        bytes calldata _data
    ) external onlyOwner {

        /// @dev Currently storing 1 photo per storage contract -- this can be optimized to chunk more data into each storage contract!
        if (_data.length != photoDataByteSize) revert InvalidMemorySequence();

        onChainStorage[_photoId] = SSTORE2.write(_data);
    }

    /// @notice Gets the data for a photo in .xqst format
    /// @dev Our renderer contract will uses this when generating the metadata
    /// @param _photoId The id of the photo -- TODO: This may have to change!
    function getPhotoData(
        uint256 _photoId
    ) external view returns (
        bytes memory
    )
    {
        return SSTORE2.read(onChainStorage[_photoId]);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

/// @author therightchoyce.eth
/// @title  Upgradeable data store interface for on-chain art storage
/// @notice This leaves room for us to change how we store data
///         unlocks future capability
interface ITheHydraDataStore {
    function setOffChainBaseURI(string memory _baseURI) external;
    function getOffChainBaseURI() external view returns (string memory);

    function storePhotoData(uint256 _photoId, bytes calldata _data) external;
    function getPhotoData(uint256 _photoId) external view returns (bytes memory);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Owned.sol)
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Read and write to persistent storage at a fraction of the cost.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SSTORE2.sol)
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