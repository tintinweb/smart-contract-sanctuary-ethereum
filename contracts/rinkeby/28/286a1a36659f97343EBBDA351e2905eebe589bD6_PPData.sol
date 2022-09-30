// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./SSTORE2Map.sol";
import "./potted_types.sol";

contract PPData is Ownable {
  PottedTypes.Potted[] private potteds;
  PottedTypes.Branch[] private branches;
  PottedTypes.Blossom[] private blossoms;

  string constant pottedImageKey = "bottom";
  string constant brachImageKey = "branch";
  string constant blossomImageKey = "blossom";

  enum Structure {
    potted,
    branch,
    blossom
  }

  function getAllPotted() external view returns (PottedTypes.Potted[] memory) {
    return potteds;
  }

  function getAllBranch() external view returns (PottedTypes.Branch[] memory) {
    return branches;
  }

  function getAllBlossom() external view returns (PottedTypes.Blossom[] memory) {
    return blossoms;
  }

  function updatePotted(uint index, PottedTypes.Potted memory newData) external onlyOwner {
    potteds[index] = newData;
  }

  function updateBranch(uint index, PottedTypes.Branch memory newData) external onlyOwner {
    branches[index] = newData;
  }

  function updateBlossom(uint index, PottedTypes.Blossom memory newData) external onlyOwner {
    blossoms[index] = newData;
  }

  function setPotteds(PottedTypes.Potted[] calldata _potted) external onlyOwner {
    for (uint i; i < _potted.length; i++) {
      potteds.push(_potted[i]);
    } 
  }

  function setBranches(PottedTypes.Branch[] calldata _branch) external onlyOwner {
    for (uint i; i < _branch.length; i++) {
      branches.push(_branch[i]);
    } 
  }

  function setBlossoms(PottedTypes.Blossom[] calldata _blossom) external onlyOwner {
    for (uint i; i < _blossom.length; i++) {
      blossoms.push(_blossom[i]);
    } 
  }

  function setHashes(Structure _structure, bytes[] calldata _hashes) external onlyOwner {
    string memory key = structureToKey(_structure);
    SSTORE2Map.write(key, abi.encode(_hashes));
  }
  
  function getHashes(Structure _structure) external view returns (bytes[] memory) {
    string memory key = structureToKey(_structure);
    return abi.decode(SSTORE2Map.read(key), (bytes[]));
  }

  function structureToKey(Structure _structure) private pure returns (string memory) {
    string memory key;
    if (_structure == Structure.potted) {
      key = pottedImageKey;
    } else if (_structure == Structure.branch) {
      key = brachImageKey;
    } else if (_structure == Structure.blossom) {
      key = blossomImageKey;
    }

    return key;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface PottedTypes {
    struct Gene {
        uint dna;
        uint revealNum;
    }

    struct MyPotted {
      Potted potted;
      Branch branch;
      Blossom blossom;
    }

    struct Potted {
      string traitName;
      uint width;
      uint height;
      uint x;
      uint y;
      uint offsetY;
      uint id;
    }

    struct Branch {
      string traitName;
      uint width;
      uint height;
      uint x;
      uint[] pointX;
      uint[] pointY;
      uint id;
    }

    // Each blossom max count <= branchPointX.length
    struct Blossom {
      string traitName;
      uint[] width;
      uint[] height;
      uint[] childs;
      uint id;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Create3.sol";
import "./Bytecode.sol";


/**
  @title A write-once key-value storage for storing chunks of data with a lower write & read cost.
  @author Agustin Aguilar <[email protected]>

  Readme: https://github.com/0xsequence/sstore2#readme
*/
library SSTORE2Map {
  error WriteError();

  //                                         keccak256(bytes('@0xSequence.SSTORE2Map.slot'))
  bytes32 private constant SLOT_KEY_PREFIX = 0xd351a9253491dfef66f53115e9e3afda3b5fdef08a1de6937da91188ec553be5;

  function internalKey(bytes32 _key) internal pure returns (bytes32) {
    // Mutate the key so it doesn't collide
    // if the contract is also using CREATE3 for other things
    return keccak256(abi.encode(SLOT_KEY_PREFIX, _key));
  }

  /**
    @notice Stores `_data` and returns `pointer` as key for later retrieval
    @dev The pointer is a contract address with `_data` as code
    @param _data To be written
    @param _key unique string key for accessing the written data (can only be used once)
    @return pointer Pointer to the written `_data`
  */
  function write(string memory _key, bytes memory _data) internal returns (address pointer) {
    return write(keccak256(bytes(_key)), _data);
  }

  /**
    @notice Stores `_data` and returns `pointer` as key for later retrieval
    @dev The pointer is a contract address with `_data` as code
    @param _data to be written
    @param _key unique bytes32 key for accessing the written data (can only be used once)
    @return pointer Pointer to the written `_data`
  */
  function write(bytes32 _key, bytes memory _data) internal returns (address pointer) {
    // Append 00 to _data so contract can't be called
    // Build init code
    bytes memory code = Bytecode.creationCodeFor(
      abi.encodePacked(
        hex'00',
        _data
      )
    );

    // Deploy contract using create3
    pointer = Create3.create3(internalKey(_key), code);
  }

  /**
    @notice Reads the contents for a given `_key`, it maps to a contract code as data, skips the first byte
    @dev The function is intended for reading pointers first written by `write`
    @param _key string key that constains the data
    @return data read from contract associated with `_key`
  */
  function read(string memory _key) internal view returns (bytes memory) {
    return read(keccak256(bytes(_key)));
  }

  /**
    @notice Reads the contents for a given `_key`, it maps to a contract code as data, skips the first byte
    @dev The function is intended for reading pointers first written by `write`
    @param _key string key that constains the data
    @param _start number of bytes to skip
    @return data read from contract associated with `_key`
  */
  function read(string memory _key, uint256 _start) internal view returns (bytes memory) {
    return read(keccak256(bytes(_key)), _start);
  }

  /**
    @notice Reads the contents for a given `_key`, it maps to a contract code as data, skips the first byte
    @dev The function is intended for reading pointers first written by `write`
    @param _key string key that constains the data
    @param _start number of bytes to skip
    @param _end index before which to end extraction
    @return data read from contract associated with `_key`
  */
  function read(string memory _key, uint256 _start, uint256 _end) internal view returns (bytes memory) {
    return read(keccak256(bytes(_key)), _start, _end);
  }

  /**
    @notice Reads the contents for a given `_key`, it maps to a contract code as data, skips the first byte
    @dev The function is intended for reading pointers first written by `write`
    @param _key bytes32 key that constains the data
    @return data read from contract associated with `_key`
  */
  function read(bytes32 _key) internal view returns (bytes memory) {
    return Bytecode.codeAt(Create3.addressOf(internalKey(_key)), 1, type(uint256).max);
  }

  /**
    @notice Reads the contents for a given `_key`, it maps to a contract code as data, skips the first byte
    @dev The function is intended for reading pointers first written by `write`
    @param _key bytes32 key that constains the data
    @param _start number of bytes to skip
    @return data read from contract associated with `_key`
  */
  function read(bytes32 _key, uint256 _start) internal view returns (bytes memory) {
    return Bytecode.codeAt(Create3.addressOf(internalKey(_key)), _start + 1, type(uint256).max);
  }

  /**
    @notice Reads the contents for a given `_key`, it maps to a contract code as data, skips the first byte
    @dev The function is intended for reading pointers first written by `write`
    @param _key bytes32 key that constains the data
    @param _start number of bytes to skip
    @param _end index before which to end extraction
    @return data read from contract associated with `_key`
  */
  function read(bytes32 _key, uint256 _start, uint256 _end) internal view returns (bytes memory) {
    return Bytecode.codeAt(Create3.addressOf(internalKey(_key)), _start + 1, _end + 1);
  }
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

/**
  @title A library for deploying contracts EIP-3171 style.
  @author Agustin Aguilar <[email protected]>
*/
library Create3 {
  error ErrorCreatingProxy();
  error ErrorCreatingContract();
  error TargetAlreadyExists();

  /**
    @notice The bytecode for a contract that proxies the creation of another contract
    @dev If this code is deployed using CREATE2 it can be used to decouple `creationCode` from the child contract address

  0x67363d3d37363d34f03d5260086018f3:
      0x00  0x67  0x67XXXXXXXXXXXXXXXX  PUSH8 bytecode  0x363d3d37363d34f0
      0x01  0x3d  0x3d                  RETURNDATASIZE  0 0x363d3d37363d34f0
      0x02  0x52  0x52                  MSTORE
      0x03  0x60  0x6008                PUSH1 08        8
      0x04  0x60  0x6018                PUSH1 18        24 8
      0x05  0xf3  0xf3                  RETURN

  0x363d3d37363d34f0:
      0x00  0x36  0x36                  CALLDATASIZE    cds
      0x01  0x3d  0x3d                  RETURNDATASIZE  0 cds
      0x02  0x3d  0x3d                  RETURNDATASIZE  0 0 cds
      0x03  0x37  0x37                  CALLDATACOPY
      0x04  0x36  0x36                  CALLDATASIZE    cds
      0x05  0x3d  0x3d                  RETURNDATASIZE  0 cds
      0x06  0x34  0x34                  CALLVALUE       val 0 cds
      0x07  0xf0  0xf0                  CREATE          addr
  */
  
  bytes internal constant PROXY_CHILD_BYTECODE = hex"67_36_3d_3d_37_36_3d_34_f0_3d_52_60_08_60_18_f3";

  //                        KECCAK256_PROXY_CHILD_BYTECODE = keccak256(PROXY_CHILD_BYTECODE);
  bytes32 internal constant KECCAK256_PROXY_CHILD_BYTECODE = 0x21c35dbe1b344a2488cf3321d6ce542f8e9f305544ff09e4993a62319a497c1f;

  /**
    @notice Returns the size of the code on a given address
    @param _addr Address that may or may not contain code
    @return size of the code on the given `_addr`
  */
  function codeSize(address _addr) internal view returns (uint256 size) {
    assembly { size := extcodesize(_addr) }
  }

  /**
    @notice Creates a new contract with given `_creationCode` and `_salt`
    @param _salt Salt of the contract creation, resulting address will be derivated from this value only
    @param _creationCode Creation code (constructor) of the contract to be deployed, this value doesn't affect the resulting address
    @return addr of the deployed contract, reverts on error
  */
  function create3(bytes32 _salt, bytes memory _creationCode) internal returns (address addr) {
    return create3(_salt, _creationCode, 0);
  }

  /**
    @notice Creates a new contract with given `_creationCode` and `_salt`
    @param _salt Salt of the contract creation, resulting address will be derivated from this value only
    @param _creationCode Creation code (constructor) of the contract to be deployed, this value doesn't affect the resulting address
    @param _value In WEI of ETH to be forwarded to child contract
    @return addr of the deployed contract, reverts on error
  */
  function create3(bytes32 _salt, bytes memory _creationCode, uint256 _value) internal returns (address addr) {
    // Creation code
    bytes memory creationCode = PROXY_CHILD_BYTECODE;

    // Get target final address
    addr = addressOf(_salt);
    if (codeSize(addr) != 0) revert TargetAlreadyExists();

    // Create CREATE2 proxy
    address proxy; assembly { proxy := create2(0, add(creationCode, 32), mload(creationCode), _salt)}
    if (proxy == address(0)) revert ErrorCreatingProxy();

    // Call proxy with final init code
    (bool success,) = proxy.call{ value: _value }(_creationCode);
    if (!success || codeSize(addr) == 0) revert ErrorCreatingContract();
  }

  /**
    @notice Computes the resulting address of a contract deployed using address(this) and the given `_salt`
    @param _salt Salt of the contract creation, resulting address will be derivated from this value only
    @return addr of the deployed contract, reverts on error

    @dev The address creation formula is: keccak256(rlp([keccak256(0xff ++ address(this) ++ _salt ++ keccak256(childBytecode))[12:], 0x01]))
  */
  function addressOf(bytes32 _salt) internal view returns (address) {
    address proxy = address(
      uint160(
        uint256(
          keccak256(
            abi.encodePacked(
              hex'ff',
              address(this),
              _salt,
              KECCAK256_PROXY_CHILD_BYTECODE
            )
          )
        )
      )
    );

    return address(
      uint160(
        uint256(
          keccak256(
            abi.encodePacked(
              hex"d6_94",
              proxy,
              hex"01"
            )
          )
        )
      )
    );
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