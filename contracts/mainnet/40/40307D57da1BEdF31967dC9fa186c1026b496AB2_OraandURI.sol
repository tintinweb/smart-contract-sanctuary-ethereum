/**
 *Submitted for verification at Etherscan.io on 2022-11-13
*/

/******************************************************************************************
 ________  ________  ________  ________  ________   ________  ___  ___  ________  ___     
|\   __  \|\   __  \|\   __  \|\   __  \|\   ___  \|\   ___ \|\  \|\  \|\   __  \|\  \    
\ \  \|\  \ \  \|\  \ \  \|\  \ \  \|\  \ \  \\ \  \ \  \_|\ \ \  \\\  \ \  \|\  \ \  \   
 \ \  \\\  \ \   _  _\ \   __  \ \   __  \ \  \\ \  \ \  \ \\ \ \  \\\  \ \   _  _\ \  \  
  \ \  \\\  \ \  \\  \\ \  \ \  \ \  \ \  \ \  \\ \  \ \  \_\\ \ \  \\\  \ \  \\  \\ \  \ 
   \ \_______\ \__\\ _\\ \__\ \__\ \__\ \__\ \__\\ \__\ \_______\ \_______\ \__\\ _\\ \__\
    \|_______|\|__|\|__|\|__|\|__|\|__|\|__|\|__| \|__|\|_______|\|_______|\|__|\|__|\|__|
                                                                                          
This contract will output the metadata for oraand tokens                                                                               

the animation_url metadata attribute will contain a base64 encoded HTML page which will display the token

the HTML page is assembled from the PRG data for the token and HTML/JS parts stored onchain with sstore2

*******************************************************************************************/



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

// File: oraanduri-base64.sol

pragma solidity ^0.8.14;



interface IOraandURI {
  function tokenURI(IOraandPRGToken tokenContract, uint256 tokenId) external view returns (string memory);
}

interface IOraandPRGToken {
  function getTokenPRGBase64(uint256 tokenId, bool patchedVersion) external view returns (string memory);
  function getTokenPRG(uint256 tokenId, bool pal, uint8 filterResonanceRouting, uint8 filterModeVolume) external view returns (bytes memory);
  function getTokenPatchedPRG(uint256 tokenId, bool pal, uint8 filterResonanceRouting, uint8 filterModeVolume) external view returns (bytes memory);
  function getTokenAttributes(uint256 tokenId) external view returns (string memory);
  function getTokenParams(uint256 tokenId) external view returns (uint64);
  function getTokenModes(uint256 tokenId) external view returns (uint8);
  function getTokenPatchUnlocked(uint256 tokenId) external view returns (bool);
}

contract OraandURI is Ownable, IOraandURI {
  using Strings for uint256;

  string private imageBaseURI     = "https://nopsta.com/oraand/i/";
  string private animationBaseURI = "https://nopsta.com/oraand/v/";
  string private externalBaseURI  = "https://nopsta.com/oraand/";
  string private description      = "2048 byte on chain programs for the Commodore 64";

  // used to determine some attributes
  bytes constant prgData7 = hex"000b0b0402060d010a0c0b06060e000f000f0f010b0d01000607000f000b0e06";
  bytes constant prgData8 = hex"010f000101010506020b0c0e0e060f0b0f0b0004010002070302030b010f060e";

  string internal constant HEXTABLE = "0123456789abcdef";

  address[] HEADPARTS = [
    0x26Bc865386eCCaD0021dB8f5159Fd58E1432D412, // oraand-head
    0x1Cc49e603B4b205Be0E74f8833971Bea5beccEC9, // gzip
    0xEF13021d5302c3fCe437A3C281A286479ba60008, // m64-part0
    0x9A463234988C0F77ca1252Fc974DfD6b50AAA6Ba, // m64-part1
    0xf6Fb8cefFff7239d9689acDF1FBF5376C9996dA5  // m64-part2
  ];

  address[] TAILPARTS = [
    0x38b6C4e3827A6EA0E853d532537AA26a3cFAf841  // oraand-tail
  ];

  // return json metadata as a data URI with base 64 encoded data
  function tokenURI(IOraandPRGToken tokenContract, uint256 tokenId)
    override
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

    return string.concat('data:application/json;base64,', base64Encode(bytes(string.concat(
      '{"name":"oraand ', tokenIdString,
      '","description":"', description, 
      '","attributes":',
      getAttributes(params, modes, patchUnlocked),
      getTokenURIs(tokenIdString),
      getAnimationURL(modes, prgData, patchPRGData),
      '"}'
    ))));
  }
 
  // return sstore2d data as string
  function getParts(address[] memory parts)
    internal
    view
    returns (string memory output)
  {
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

  // convert bytes to string of hex digits
  function getPRGData(bytes memory prgData) internal pure returns (string memory output) {
    // copy the table to memory
    string memory table = HEXTABLE;

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
      // be character of the offset in the table string
      let tablePtr := add(table, 1)

      let srcPtr := prgData
      let outputPtr := add(output, 0x20)

      let len := mload(srcPtr)

      // loop over the prg data, 32 bytes at a time
      for { i := 0 } lt(i, len) { i := add(i, 0x20) } {

        // the first loop iteration will skip past the length 32 bytes
        srcPtr := add(srcPtr, 0x20)

        // load in 32 bytes
        let input := mload(srcPtr)
        let shiftAmount := 252

        // go over each nibble in the 32 bytes and look up its string hex code in table
        for { let j := 256 } gt(j, 0) {} {
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

  function getTokenURIs(string memory tokenIdString)
    internal
    view
    returns (string memory)
  {
    string memory uriString = string.concat(
      ',"image":"', imageBaseURI, tokenIdString,
      '.png","external_url":"', externalBaseURI, tokenIdString, '"'
      ',"animation_url":"data:text/html;base64,'
    );

    return uriString;
  }

  function getAttributes(uint64 params, uint modes, bool patchUnlocked)
    internal
    pure
    returns (string memory)
  {
      uint8 param = uint8((params >> 8) & 0x1f);

      string memory patch = "No";
      if(patchUnlocked) {
        patch = "Yes";
      }

      return string.concat(
          '[{"trait_type":"Type","value":"',
          Strings.toHexString(params & 7, 1),'"},{"trait_type":"FG","value":"',
          Strings.toHexString(uint8(prgData7[param]), 1) ,'"},{"trait_type":"BG","value":"',
          Strings.toHexString(uint8(prgData8[param]), 1) ,'"}, {"trait_type":"Charset","value":"',
          Strings.toHexString((params >> 32) & 0x1f, 1),'"},{"trait_type":"Modes","value":"',
          Strings.toHexString(modes, 1),
          '"}, {"trait_type":"Patch","value":"', patch,
          '"}]'
      );
  }

  function getAnimationURL(uint modes, bytes memory prgData, string memory patchPrgData)
    internal
    view
    returns (string memory)
  {
      return base64Encode(bytes(string.concat(
          getParts(HEADPARTS),
          '<script>var prg_hex ="',
          getPRGData(prgData),
          '";var patch_hex ="',
          patchPrgData,
          '";var modes = ',
          Strings.toString(modes),
          ';</script>',
        getParts(TAILPARTS)
      )));
  }

  // ------------------------ contract owner ------------------------ //

  function setImageBaseURI(string memory baseURI)
    external
    Ownable.onlyOwner
  {
    imageBaseURI = baseURI;
  }

  function setExternalBaseURI(string memory baseURI)
    external
    Ownable.onlyOwner
  {
    externalBaseURI = baseURI;
  }

  function setDescription(string memory desc)
    external
    Ownable.onlyOwner
  {
    description = desc;
  }

  function setHeadParts(address[] memory pointers)
    external
    Ownable.onlyOwner
  {
    HEADPARTS = pointers;
  }

  function setTailParts(address[] memory pointers)
    external
    Ownable.onlyOwner
  {
    TAILPARTS = pointers;
  }


  // ---------------------------- base64 ---------------------------- //

  // From OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol) - MIT Licence
  // @dev Base64 Encoding/Decoding Table
  string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

  //@dev Converts a `bytes` to its Bytes64 `string` representation.

  function base64Encode(bytes memory data) internal pure returns (string memory) {

      // Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
      // https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
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