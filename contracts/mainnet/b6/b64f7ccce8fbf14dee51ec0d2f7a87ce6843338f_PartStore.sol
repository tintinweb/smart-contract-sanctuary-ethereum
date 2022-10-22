/**
 *Submitted for verification at Etherscan.io on 2022-10-22
*/

// File: @openzeppelin/contracts/utils/Strings.sol


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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: partstore.sol


pragma solidity ^0.8.4;



// store strings, max 24kb each, map the strings to keys
// code is mostly from sstore2
// https://github.com/0xsequence/sstore2
// https://github.com/Vectorized/solady/blob/main/src/utils/SSTORE2.sol

interface IPartStore {
  // get an array of all the part keys
  function getKeys() external view returns (string[] memory);
  // get the address of a part for a key
  function getAddress(string memory key) external view returns (address);
  // return the part stored at an address
  function read(address pointer)  external view returns (string memory data);
}

contract PartStore is Ownable, IPartStore {
  using Strings for uint256;

  // some keys and a map, just to give a label to parts
  string[] keys;
  mapping(string => address) public partMap;

  // get an array of all the keys
  function getKeys() 
    override(IPartStore)
    external view
    returns (string[] memory)
  {
    return keys;
  }

  // get an address for a key
  function getAddress(string memory key) 
    override(IPartStore)
    external view
    returns (address)
  {
    return partMap[key];
  }

  // read a part at an address
  function read(address pointer) 
    override(IPartStore)
    external view 
    returns (string memory data) 
  {
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

  /// @dev Writes `data` into the bytecode of a storage contract and returns its address.
  function write(string memory key, string memory data) 
    external
    Ownable.onlyOwner    
    returns (address theaddress) 
  {
    address pointer;

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

    if(partMap[key] == address(0)) {
      keys.push(key);
    }

    partMap[key] = pointer;
    return pointer;
  }
}