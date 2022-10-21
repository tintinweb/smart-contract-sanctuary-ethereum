/**
 *Submitted for verification at Etherscan.io on 2022-10-21
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

// File: beqstauri.sol

pragma solidity ^0.8.14;



interface IBeqstaURI {
  function tokenURI(IBeqstaPRGToken tokenContract, uint256 tokenId) external view returns (string memory);
}

interface IBeqstaPRGToken {
  function getTokenPRGBase64(uint256 tokenId, bool patchedVersion) external view returns (string memory);
  function getTokenPRG(uint256 tokenId, bool pal, uint8 filterResonanceRouting, uint8 filterModeVolume) external view returns (bytes memory);
  function getTokenPatchedPRG(uint256 tokenId, bool pal, uint8 filterResonanceRouting, uint8 filterModeVolume) external view returns (bytes memory);
  function getTokenAttributes(uint256 tokenId) external view returns (string memory);
  function getTokenParams(uint256 tokenId) external view returns (uint64);
  function getTokenModes(uint256 tokenId) external view returns (uint8);
  function getTokenPatchUnlocked(uint256 tokenId) external view returns (bool);
}

contract BeqstaURI is Ownable, IBeqstaURI {
  using Strings for uint256;

  string private imageBaseURI     = "https%3A%2F%2Fnopsta.com%2Fbeqsta%2Fi%2F";
  string private externalBaseURI  = "https%3A%2F%2Fnopsta.com%2Fbeqsta%2F";
  string private description = "testtesttest";

  bytes constant prgData7 = hex"000b0b0402060d010a0c0b06060e000f000f0f010b0d01000607000f000b0e06";
  bytes constant prgData8 = hex"010f000101010506020b0c0e0e060f0b0f0b0004010002070302030b010f060e";

  string internal constant TABLE = "0123456789abcdef";

  address[] HEADPARTS = [
      0x464C40Fd0435E3CDa2993fa283EFD453Bf472e8d,
      0x84a58F4DA9F25888C0dEC542C7E43559CfA6fCCf
  ];

  address[] TAILPARTS = [
      0xC7cd5CB5C4B545681B153e415556Aa3b18f4aF68 
  ];

  function setHeadParts(address[] memory pointers) 
    external
    Ownable.onlyOwner
  {
    HEADPARTS = pointers;
  }
  
  function setTailParts(address[] memory pointers) public {
    TAILPARTS = pointers;
  }

  function getParts(address[] memory parts) public view returns (string memory output) {
    assembly {
      // read the 32 bytes of memory at 0x40
      // 0x40 points to the end of currently allocated memory
      output := mload(0x40)

      // first 32 bytes are the length
      let totalSize := 0x20

      let len := mload(parts)
      let size := 0
      let targetPart := 0x0
      for { let i := 0 } lt(i, len) { i := add(i, 1) } {
        // get the part pointer
        targetPart := mload(add(parts, add(0x20, mul(i, 0x20))))
        size := sub(extcodesize(targetPart), 1)

        // copy to output at position total size
        extcodecopy(targetPart, add(output, totalSize), 1, size)
        totalSize := add(totalSize, size)
      }

      // write the string length
      mstore(output, sub(totalSize, 0x20))

      // update the pointer to new end of memory
      // make the pointer a multiple of 0x20
      mstore(0x40, add(output, and(add(totalSize, 0x1f), not(0x1f)))) 
    }
  }


  function getPRGData(bytes memory prgData) internal pure returns (string memory output) {
    // copy the table to memory
    string memory table = TABLE;

    assembly {
      // read the 32 bytes of memory at 0x40
      // 0x40 points to the end of currently allocated memory
      output := mload(0x40)

      // first 32 bytes are the length
      let totalSize := 0x20

      let c := 0
      let i := 0

      // read in the prg data

      // skip the first byte of the table
      // so when using mload with tablePtr and offset
      // the last byte of the 32 bytes returned will  
      // be the character at the offset in the table string
      let tablePtr := add(table, 1)

      let srcPtr := prgData
      let outputPtr := add(output, 0x20)

      let len := mload(srcPtr)

      // loop over the prg data, 32 bytes at a time
      for { i := 0 } lt(i, len) { i := add(i, 0x20) } {

        // first loop iteration will skip past the length 32 bytes
        srcPtr := add(srcPtr, 0x20)

        // load in 32 bytes
        let input := mload(srcPtr)
        let shiftAmount := 252


        // should set the output ptr to 32 bytes after and shift backwards


        // go over each nibble in the 32 bytes and look up its string hex code in table
        for { let j := 256 } gt(j, 0) {} {
          // unroll it a little
          j:= sub(j, 4)
          mstore8(outputPtr, mload(add(tablePtr, and(shr(j, input), 0xF))))
          outputPtr := add(outputPtr, 1) // Advance
          j:= sub(j, 4)
          mstore8(outputPtr, mload(add(tablePtr, and(shr(j, input), 0xF))))
          outputPtr := add(outputPtr, 1) // Advance
          j:= sub(j, 4)
          mstore8(outputPtr, mload(add(tablePtr, and(shr(j, input), 0xF))))
          outputPtr := add(outputPtr, 1) // Advance
          j:= sub(j, 4)
          mstore8(outputPtr, mload(add(tablePtr, and(shr(j, input), 0xF))))
          outputPtr := add(outputPtr, 1) // Advance
          j:= sub(j, 4)
          mstore8(outputPtr, mload(add(tablePtr, and(shr(j, input), 0xF))))
          outputPtr := add(outputPtr, 1) // Advance
          j:= sub(j, 4)
          mstore8(outputPtr, mload(add(tablePtr, and(shr(j, input), 0xF))))
          outputPtr := add(outputPtr, 1) // Advance
          j:= sub(j, 4)
          mstore8(outputPtr, mload(add(tablePtr, and(shr(j, input), 0xF))))
          outputPtr := add(outputPtr, 1) // Advance
          j:= sub(j, 4)
          mstore8(outputPtr, mload(add(tablePtr, and(shr(j, input), 0xF))))
          outputPtr := add(outputPtr, 1) // Advance
        }

      }

      totalSize := sub(outputPtr, output)
      // write the string length
      mstore(output, sub(totalSize, 0x20))

      // update the pointer to new end of memory
      // make the pointer a multiple of 0x20
      mstore(0x40, add(output, and(add(totalSize, 0x1f), not(0x1f))))

    }
  }


  function tokenURI(IBeqstaPRGToken tokenContract, uint256 tokenId) 
    external
    view
    returns (string memory output)
  {
    uint64 params = tokenContract.getTokenParams(tokenId);
    bool patchUnlocked = tokenContract.getTokenPatchUnlocked(tokenId);
    uint modes = tokenContract.getTokenModes(tokenId);
    string memory tokenIdString = Strings.toString(tokenId);
    string memory patchPRGData = '';
    bytes memory prgData = tokenContract.getTokenPRG(tokenId, true, 0, 0);

    if(patchUnlocked) {
      patchPRGData = getPRGData(tokenContract.getTokenPatchedPRG(tokenId, true, 0, 0));
    }

    return string.concat(
      'data:application/json,%7B%22name%22%3A%22oraand%20',tokenIdString,
      '%22%2C%22description%22%3A%22',description,'%22',
      getTokenURIHead(params, modes, patchUnlocked),
      getTokenURIs(tokenIdString),
      getParts(HEADPARTS),
      '%253Cscript%253E%250A%2520%2520let%2520prg_hex%2520%253D%2520%2527',
      getPRGData(prgData),
      '%2527%253B%250D%250A%2520%2520%2520%2520%2520%2520let%2520patch_hex%2520%253D%2520%2527',
      patchPRGData,
      '%2527%253B%250D%250A%2520%2520%2520%2520%2520%2520let%2520modes%2520%253D%2520',
      Strings.toString(modes),
      '%253B%250D%250A%2520%2520%2520%2520%253C%252Fscript%253E',
      getParts(TAILPARTS),
      '%22%7D'
    );
  }

  function getTokenURIs(string memory tokenIdString) 
    internal
    view 
    returns (string memory) 
  {
    string memory uriString = string.concat(
      '%22image%22%3A%22', imageBaseURI, tokenIdString,
      '.png%22%2C%22external_url%22%3A%22', externalBaseURI, tokenIdString, '%22%2C',
      '%22animation_url%22%3A%22data%3Atext%2Fhtml%2C'
    );
    return uriString;
  }    

  function getTokenURIHead(uint64 params, uint modes, bool patchUnlocked) 
    internal
    pure
    returns (string memory) 
  {
      uint8 param = uint8((params) & 0x1f);

      string memory patch = "No";
      if(patchUnlocked) {
        patch = "Yes";
      }

      return string.concat(
          '%2C%22attributes%22%3A%5B%7B%22trait_type%22%3A%22Type%22%2C%22value%22%3A%22', 
          Strings.toHexString(params & 7,2) ,'%22%7D%2C%7B%22trait_type%22%3A%22FG%22%2C%22value%22%3A%22', 
          Strings.toHexString(uint8(prgData7[param]), 2) ,'%22%7D%2C%7B%22trait_type%22%3A%22BG%22%2C%22value%22%3A%22', 
          Strings.toHexString(uint8(prgData8[param]), 2) ,'%22%7D%2C%20%7B%22trait_type%22%3A%22Charset%22%2C%22value%22%3A%22', 
          Strings.toHexString((params >> 32) & 0x1f, 2) ,'%22%7D%2C%7B%22trait_type%22%3A%22Modes%22%2C%22value%22%3A%22', 
          Strings.toHexString(modes, 2),     
          '%22%7D%2C%20%7B%22trait_type%22%3A%22Patch%22%2C%22value%22%3A%22',patch,
          '%22%7D%5D%2C'
      );    
  }
}