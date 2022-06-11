// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

/*


        .++++++    .-=+**++=:  -+++++++++++-      .-=+**.     .++++:      
         :@@@@. .+%@#++++#@@@@#=*@@@%++*@@@*   :*@@%+=-:      [email protected]@@+       
          %@@# [email protected]@+        :#@@#[email protected]@@=    :#+ .#@@*.          [email protected]@@+        
          #@@#*@@=           *@# @@@@-      [email protected]@@*+*+=-      :@@@= =       
          #@@@@@@             += @@@@@@%%%=:@@@@*++#@@@#:  :@@@--%#       
          #@@@@@@                @@@= -*@@=#@@@     .*@@@[email protected]@# [email protected]@#   =   
          #@@@@@@-               @@@=    :[email protected]@@%       #@@@@@[email protected]@%-*@@   
          #@@#%@@@-           .%@@@@=      #@@@:      [email protected]@@@@@@@@@@@@@@@   
          %@@# #@@@#-       :[email protected]%[email protected]@@=     :%@@@%.     *@@+     [email protected]@%       
         :@@@@. :*@@@@%###%@@#= [email protected]@@#++#%@@@**@@@#=-=%@%-     [email protected]@@@-      
        .*****+    :=*###*+-.  -************:  -*###*=:      :******=

        D A T A   S T O R A G E   C O N T R A C T

*/

import {Owned} from "@rari-capital/solmate/src/auth/Owned.sol";
import {SSTORE2} from "@0xsequence/sstore2/contracts/SSTORE2.sol";

import {IICE64} from "./interfaces/IICE64.sol";
import {IICE64DataStore} from "./interfaces/IICE64DataStore.sol";

/**
@title ICE64 data store
@author Sam King (samkingstudio.eth)
@notice Stores the on-chain image data for ICE64 editions. Images are in the Exquisite Graphics
        format (.xqst) for use by the rendering smart contract.

        Code is licensed as MIT.
        https://spdx.org/licenses/MIT.html

        Token metadata and images licensed as CC BY-NC 4.0
        https://creativecommons.org/licenses/by-nc/4.0/
        You are free to:
            - Share: copy and redistribute the material in any medium or format
            - Adapt: remix, transform, and build upon the material
        Under the following terms:
            - Attribution: You must give appropriate credit, provide a link to the license,
            and indicate if changes were made. You may do so in any reasonable manner, but not
            in any way that suggests the licensor endorses you or your use.
            - NonCommercial: You may not use the material for commercial purposes
            - No additional restrictions: You may not apply legal terms or technological measures
            that legally restrict others from doing anything the license permits.

*/
contract ICE64DataStore is IICE64DataStore, Owned {
    /* ------------------------------------------------------------------------
                                   S T O R A G E
    ------------------------------------------------------------------------ */

    string private _originalsBaseURI;
    uint256 private constant _photoDataByteSize = 4360;
    uint256 private constant _photoDataChunkLength = 2;
    mapping(uint256 => address) private _photoDataChunks;

    /* ------------------------------------------------------------------------
                                    E R R O R S
    ------------------------------------------------------------------------ */

    /* ADMIN --------------------------------------------------------------- */

    error InvalidPhotoData();

    /* ------------------------------------------------------------------------
                                      I N I T
    ------------------------------------------------------------------------ */

    /// @param owner The owner of the contract upon deployment
    /// @param originalsBaseURI_ The base URI for original photos (usually arweave or ipfs)
    constructor(address owner, string memory originalsBaseURI_) Owned(owner) {
        _originalsBaseURI = originalsBaseURI_;
    }

    /* ------------------------------------------------------------------------
                         O F F - C H A I N   B A S E U R I
    ------------------------------------------------------------------------ */

    /// @notice Admin function to set the baseURI for original photos (arweave or ipfs)
    /// @param baseURI The new baseURI to set
    function setOriginalsBaseURI(string memory baseURI) external onlyOwner {
        _originalsBaseURI = baseURI;
    }

    /// @notice Retrieve the currently set baseURI
    /// @dev Used by the metadata contract to construct the tokenURI
    function getBaseURI() external view returns (string memory) {
        return _originalsBaseURI;
    }

    /* ------------------------------------------------------------------------
                          O N - C H A I N   S T O R A G E
    ------------------------------------------------------------------------ */

    /// @notice Admin function to store chunked photo data for on-chain editions
    /// @dev Stores the data in chunks for more efficient storage and costs
    /// @param chunkId The chunk id to save data for
    /// @param data The packed data in .xqst format
    function storeChunkedEditionPhotoData(uint256 chunkId, bytes calldata data) external onlyOwner {
        if (data.length != _photoDataByteSize * _photoDataChunkLength) revert InvalidPhotoData();
        _photoDataChunks[chunkId] = SSTORE2.write(data);
    }

    /// @notice Gets the raw .xqst data for a given photo
    /// @dev Used by the metadata contract to read data from storage
    /// @param id The id of the photo to get data for
    function getRawPhotoData(uint256 id) external view returns (bytes memory) {
        uint256 chunkId = ((id - 1) / _photoDataChunkLength) + 1;
        uint256 chunkIndex = (id - 1) % _photoDataChunkLength;
        uint256 startBytes = chunkIndex * _photoDataByteSize;
        return SSTORE2.read(_photoDataChunks[chunkId], startBytes, startBytes + _photoDataByteSize);
    }
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./utils/Bytecode.sol";

/**
  @title A key-value storage with auto-generated keys for storing chunks of data with a lower write & read cost.
  @author Agustin Aguilar <[email protected]>

  Readme: https://github.com/0xsequence/sstore2#readme
*/
library SSTORE2 {
  error WriteError();

  /**
    @notice Stores `_data` and returns `pointer` as key for later retrieval
    @dev The pointer is a contract address with `_data` as code
    @param _data to be written
    @return pointer Pointer to the written `_data`
  */
  function write(bytes memory _data) internal returns (address pointer) {
    // Append 00 to _data so contract can't be called
    // Build init code
    bytes memory code = Bytecode.creationCodeFor(
      abi.encodePacked(
        hex'00',
        _data
      )
    );

    // Deploy contract using create
    assembly { pointer := create(0, add(code, 32), mload(code)) }

    // Address MUST be non-zero
    if (pointer == address(0)) revert WriteError();
  }

  /**
    @notice Reads the contents of the `_pointer` code as data, skips the first byte 
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @return data read from `_pointer` contract
  */
  function read(address _pointer) internal view returns (bytes memory) {
    return Bytecode.codeAt(_pointer, 1, type(uint256).max);
  }

  /**
    @notice Reads the contents of the `_pointer` code as data, skips the first byte 
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @param _start number of bytes to skip
    @return data read from `_pointer` contract
  */
  function read(address _pointer, uint256 _start) internal view returns (bytes memory) {
    return Bytecode.codeAt(_pointer, _start + 1, type(uint256).max);
  }

  /**
    @notice Reads the contents of the `_pointer` code as data, skips the first byte 
    @dev The function is intended for reading pointers generated by `write`
    @param _pointer to be read
    @param _start number of bytes to skip
    @param _end index before which to end extraction
    @return data read from `_pointer` contract
  */
  function read(address _pointer, uint256 _start, uint256 _end) internal view returns (bytes memory) {
    return Bytecode.codeAt(_pointer, _start + 1, _end + 1);
  }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.14;

interface IICE64 {
    function getOriginalTokenId(uint256 editionId) external pure returns (uint256);

    function getEditionTokenId(uint256 id) external pure returns (uint256);

    function getMaxEditions() external view returns (uint256);

    function isEdition(uint256 id) external pure returns (bool);
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.14;

interface IICE64DataStore {
    function getBaseURI() external view returns (string memory);

    function getRawPhotoData(uint256 id) external view returns (bytes memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


library Bytecode {
  error InvalidCodeAtRange(uint256 _size, uint256 _start, uint256 _end);

  /**
    @notice Generate a creation code that results on a contract with `_code` as bytecode
    @param _code The returning value of the resulting `creationCode`
    @return creationCode (constructor) for new contract
  */
  function creationCodeFor(bytes memory _code) internal pure returns (bytes memory) {
    /*
      0x00    0x63         0x63XXXXXX  PUSH4 _code.length  size
      0x01    0x80         0x80        DUP1                size size
      0x02    0x60         0x600e      PUSH1 14            14 size size
      0x03    0x60         0x6000      PUSH1 00            0 14 size size
      0x04    0x39         0x39        CODECOPY            size
      0x05    0x60         0x6000      PUSH1 00            0 size
      0x06    0xf3         0xf3        RETURN
      <CODE>
    */

    return abi.encodePacked(
      hex"63",
      uint32(_code.length),
      hex"80_60_0E_60_00_39_60_00_F3",
      _code
    );
  }

  /**
    @notice Returns the size of the code on a given address
    @param _addr Address that may or may not contain code
    @return size of the code on the given `_addr`
  */
  function codeSize(address _addr) internal view returns (uint256 size) {
    assembly { size := extcodesize(_addr) }
  }

  /**
    @notice Returns the code of a given address
    @dev It will fail if `_end < _start`
    @param _addr Address that may or may not contain code
    @param _start number of bytes of code to skip on read
    @param _end index before which to end extraction
    @return oCode read from `_addr` deployed bytecode

    Forked from: https://gist.github.com/KardanovIR/fe98661df9338c842b4a30306d507fbd
  */
  function codeAt(address _addr, uint256 _start, uint256 _end) internal view returns (bytes memory oCode) {
    uint256 csize = codeSize(_addr);
    if (csize == 0) return bytes("");

    if (_start > csize) return bytes("");
    if (_end < _start) revert InvalidCodeAtRange(csize, _start, _end); 

    unchecked {
      uint256 reqSize = _end - _start;
      uint256 maxSize = csize - _start;

      uint256 size = maxSize < reqSize ? maxSize : reqSize;

      assembly {
        // allocate output byte array - this could also be done without assembly
        // by using o_code = new bytes(size)
        oCode := mload(0x40)
        // new "memory end" including padding
        mstore(0x40, add(oCode, and(add(add(size, 0x20), 0x1f), not(0x1f))))
        // store length in memory
        mstore(oCode, size)
        // actually retrieve the code, this needs assembly
        extcodecopy(_addr, add(oCode, 0x20), _start, size)
      }
    }
  }
}