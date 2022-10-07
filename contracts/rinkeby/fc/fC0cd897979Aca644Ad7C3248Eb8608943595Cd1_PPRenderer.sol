// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "base64-sol/base64.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./potted_types.sol";

interface PPdata {
    function getAllPotted() external view returns (PottedTypes.Potted[] memory);
    function getAllBranch() external view returns (PottedTypes.Branch[] memory);
    function getAllBlossom() external view returns (PottedTypes.Blossom[] memory);
    function getPottedImages() external view returns (bytes[] memory);
    function getBranchImages() external view returns (bytes[] memory);
    function getBlossomImages() external view returns (bytes[] memory);
}

contract PPRenderer is Ownable {
    address public coreContract = 0x446C2988a1E471E15f8dD565b14C2e282eF03495;
    PPdata public ppData = PPdata(0x4f88E792B76c01D37e1aF675D7FeF894f90Ea23E);
    uint[] pottedCoverage = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21];
    uint[] branchCoverage = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23];
    uint[] blossomCoverage = [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24];
    uint constant cW = 64;
    uint constant cH = 96;

    modifier onlyCore {
      require(true);
        // require(msg.sender == coreContract);
        _;
    }

    function drawPotted(PottedTypes.MyPotted memory myPotted) private view returns (string memory) {
      bytes[] memory imageData = ppData.getPottedImages();
      return string(abi.encodePacked(
        '<image x="',Strings.toString(myPotted.potted.x),'" y="',Strings.toString(myPotted.potted.y),'" width="',Strings.toString(myPotted.potted.width),'" height="',Strings.toString(myPotted.potted.height),'" image-rendering="pixelated" xlink:href="data:image/png;base64,',Base64.encode(bytes(imageData[myPotted.potted.id])),'"/>'
      ));
    }

    function drawBranch(PottedTypes.MyPotted memory myPotted) private view returns (string memory) {
      bytes[] memory imageData = ppData.getBranchImages();
      return string(abi.encodePacked(
        '<image x="',Strings.toString(myPotted.branch.x),'" y="',Strings.toString(myPotted.branch.y),'" width="',Strings.toString(myPotted.branch.width),'" height="',Strings.toString(myPotted.branch.height),'" image-rendering="pixelated" xlink:href="data:image/png;base64,',Base64.encode(bytes(imageData[myPotted.branch.id])),'"/>'
      ));
    }

    function drawBlossom(PottedTypes.MyPotted memory myPotted, PottedTypes.Gene memory gene) private view returns (string memory) {
      bytes[] memory imageData = ppData.getBlossomImages();
      uint blossomCount = (gene.dna + gene.revealNum - 1) % myPotted.branch.pointX.length;
      uint currentPosIdx = blossomCount;

      string memory bloosomSvgString = '';
      for (uint i = 0; i < blossomCount; i++) {
        uint randomBlossom = (gene.dna + gene.revealNum + i + 1) % myPotted.blossom.childs.length;

        bloosomSvgString = string(abi.encodePacked(
          bloosomSvgString,
          '<image x="',Strings.toString(myPotted.branch.pointX[currentPosIdx] - (myPotted.blossom.width[randomBlossom] / 2)),'" y="',Strings.toString(myPotted.branch.pointY[currentPosIdx] - (myPotted.blossom.height[randomBlossom] / 2)),'" width="',Strings.toString(myPotted.blossom.width[randomBlossom]),'" height="',Strings.toString(myPotted.blossom.height[randomBlossom]),'" image-rendering="pixelated" xlink:href="data:image/png;base64,',Base64.encode(bytes(imageData[myPotted.blossom.childs[randomBlossom]])),'"/>'
        ));

        currentPosIdx--;
      }

      return bloosomSvgString;
    }

    function drawUnrevealPP(PottedTypes.Gene memory gene) external onlyCore view returns (string memory)  {
      PottedTypes.MyPotted memory myPotted = getPP(gene);
        return string(abi.encodePacked(
          '<svg width="',Strings.toString(cW * 10),'" height="',Strings.toString(cH * 10),'" viewBox="0 0 ',Strings.toString(cW),' ',Strings.toString(cH),'" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
          drawPotted(myPotted),
          //drawBg
          "</svg>"
        ));
    }

    function drawRevealPP(PottedTypes.Gene memory gene) external onlyCore view returns (string memory) {
      PottedTypes.MyPotted memory myPotted = getPP(gene);
        return string(abi.encodePacked(
          '<svg width="',Strings.toString(cW * 10),'" height="',Strings.toString(cH * 10),'" viewBox="0 0 ',Strings.toString(cW),' ',Strings.toString(cH),'" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
          drawPotted(myPotted),
          drawBranch(myPotted),
          drawBlossom(myPotted, gene),
          //drawBg
          "</svg>"
        ));
    }

    function drawNoBgPP(PottedTypes.Gene memory gene, uint resulotion) external onlyCore view returns (string memory) {
      PottedTypes.MyPotted memory myPotted = getPP(gene);
        return string(abi.encodePacked(
          '<svg width="',Strings.toString(cW * resulotion),'" height="',Strings.toString(cH * resulotion),'" viewBox="0 0 ',Strings.toString(cW),' ',Strings.toString(cH),'" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">',
          drawPotted(myPotted),
          drawBranch(myPotted),
          drawBlossom(myPotted, gene),
          "</svg>"
        ));
    }   

    function getPP(PottedTypes.Gene memory gene) public onlyCore view returns (PottedTypes.MyPotted memory) {
      return PottedTypes.MyPotted(getPotted(gene), getBranch(gene), getBlossom(gene));
    }

    function getPotted(PottedTypes.Gene memory gene) private view returns (PottedTypes.Potted memory) {
      uint idx = (gene.dna + 1) % pottedCoverage.length;
      return ppData.getAllPotted()[pottedCoverage[idx]];
    }

    function getBranch(PottedTypes.Gene memory gene) private view returns (PottedTypes.Branch memory) {
      uint idx = (gene.dna + gene.revealNum + 2) % branchCoverage.length;
      return ppData.getAllBranch()[branchCoverage[idx]];
    }

    function getBlossom(PottedTypes.Gene memory gene) private view returns (PottedTypes.Blossom memory) {
      PottedTypes.Branch memory branch = getBranch(gene);

      if (branch.unique != 0) {
        return ppData.getAllBlossom()[branch.unique];
      } else {
        uint idx = (gene.dna + gene.revealNum + 3) % blossomCoverage.length;
        return ppData.getAllBlossom()[blossomCoverage[idx]];
      }
    }

    function setDataContract(address _address) external onlyOwner {
      ppData = PPdata(_address);
    }

    function setCoreContract(address _address) external onlyOwner {
      coreContract = _address;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface PottedTypes {
    struct Gene {
        uint dna;
        uint revealNum;
        bool isReroll;
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
      uint id;
    }

    struct Branch {
      string traitName;
      uint width;
      uint height;
      uint unique;
      uint x;
      uint y;
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