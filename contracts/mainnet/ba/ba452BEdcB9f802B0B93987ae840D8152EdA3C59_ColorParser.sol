//SPDX-License-Identifier: CC-BY-SA-4.0

pragma solidity ^0.8.7;

import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import './Base64.sol';

interface IOldColors {
  function getCOLORData(uint256 tokenId)
    external
    view
    returns (
      uint32,
      uint32,
      uint32,
      uint32,
      uint32,
      address
    );

  function MAX_COLORS() external view returns (uint256);

  function ownerOf(uint256 tokenId) external view returns (address);

  function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface ISecrets {
  function setSecret(
    uint256 tokenId,
    string memory secret,
    string memory trait
  ) external view;

  function renderSecret(uint256 tokenId) external view returns (string memory);

  function renderSecretsData(uint256 tokenId)
    external
    view
    returns (string memory);
}

contract ColorParser is Ownable {
  using Strings for uint256;

  IOldColors colorsContract;
  ISecrets secretsContract;
  string description;

  constructor(address _oldColors, address _secrets) Ownable() {
    colorsContract = IOldColors(_oldColors);
    secretsContract = ISecrets(_secrets);
  }

  function buildColorString(
    uint32 colorR,
    uint32 colorG,
    uint32 colorB
  ) internal pure returns (string memory) {
    // GREY Adjust contrast
    if (
      colorR < 140 &&
      colorR >= 100 &&
      colorG < 140 &&
      colorG >= 100 &&
      colorB < 140 &&
      colorB >= 100
    ) {
      colorR = colorR / 3;
      colorG = colorG / 3;
      colorB = colorB / 3;
    }

    return
      string(
        abi.encodePacked(
          'rgb(',
          Strings.toString(colorR),
          ',',
          Strings.toString(colorG),
          ',',
          Strings.toString(colorB),
          ')'
        )
      );
  }

  function buildXTextPosition(uint32 positionX, uint32 positionY)
    internal
    pure
    returns (string memory)
  {
    return
      positionX > 65 && positionY > 70
        ? Strings.toString(96)
        : Strings.toString(96);
  }

  function buildYTextPosition(uint32 positionX, uint32 positionY)
    internal
    pure
    returns (string memory)
  {
    return
      positionX > 65 && positionY > 70
        ? Strings.toString(8)
        : Strings.toString(94);
  }

  function buildSVG(
    uint32 colorR,
    uint32 colorG,
    uint32 colorB,
    uint32 positionX,
    uint32 positionY,
    uint256 tokenId
  ) internal view returns (string memory) {
    string memory result = string(
      abi.encodePacked(
        '<svg version="1.1" xmlns="http://www.w3.org/2000/svg" x="0px" y="0px" viewBox="0 0 100 100"><rect x="0" y="0" width="100" height="100" fill="',
        buildColorString(colorR, colorG, colorB),
        '"/><circle cx="',
        Strings.toString(positionX),
        '.5" cy="',
        Strings.toString(positionY),
        '.5" r="4" fill="',
        buildColorString(255 - colorR, 255 - colorG, 255 - colorB),
        '"/><rect x="',
        Strings.toString(positionX),
        '" y="',
        Strings.toString(positionY),
        '" width="1" height="1" fill="',
        buildColorString(colorR, colorG, colorB),
        '"/>',
        secretsContract.renderSecret(tokenId)
      )
    );

    result = string(
      abi.encodePacked(
        result,
        '<text id="coordsText" text-anchor="end" font-family="Arial Black" dominant-baseline="middle" transform="matrix(0.5 0 0 0.5 ',
        buildXTextPosition(positionX, positionY),
        ' ',
        buildYTextPosition(positionX, positionY),
        ')" fill="',
        buildColorString(255 - colorR, 255 - colorG, 255 - colorB),
        '">',
        Strings.toString(positionX),
        ':',
        Strings.toString(positionY),
        '</text>',
        '</svg>'
      )
    );

    return result;
  }

  function buildTraits(uint256 tokenId) internal view returns (string memory) {
    (
      uint32 colorR,
      uint32 colorG,
      uint32 colorB,
      uint32 positionX,
      uint32 positionY,
      address owner
    ) = colorsContract.getCOLORData(tokenId);

    return
      string(
        abi.encodePacked(
          '[{"trait_type": "Position", "value": "',
          Strings.toString(positionX),
          ':',
          Strings.toString(positionY),
          '"},',
          '{"trait_type": "Color: RGB", "value": "',
          Strings.toString(colorR),
          ',',
          Strings.toString(colorG),
          ',',
          Strings.toString(colorB),
          '"}',
          secretsContract.renderSecretsData(tokenId),
          '],'
        )
      );
  }

  function tokenURI(uint256 tokenId) public view returns (string memory) {
    require(tokenId >= 0 && tokenId < colorsContract.MAX_COLORS());

    (
      uint32 colorR,
      uint32 colorG,
      uint32 colorB,
      uint32 positionX,
      uint32 positionY,
      address owner
    ) = colorsContract.getCOLORData(tokenId);

    string memory output = buildSVG(
      colorR,
      colorG,
      colorB,
      positionX,
      positionY,
      tokenId
    );

    string memory json = Base64.encode(
      bytes(
        string(
          abi.encodePacked(
            '{"name":',
            buildTitle(tokenId),
            ',"description":"',
            description,
            '","attributes": ',
            buildTraits(tokenId),
            '"image": "data:image/svg+xml;base64,',
            Base64.encode(bytes(output)),
            '"}'
          )
        )
      )
    );

    return string(abi.encodePacked('data:application/json;base64,', json));
  }

  function buildTitle(uint256 tokenId) internal view returns (string memory) {
    (
      uint32 colorR,
      uint32 colorG,
      uint32 colorB,
      uint32 positionX,
      uint32 positionY,
      address owner
    ) = colorsContract.getCOLORData(tokenId);
    return
      string(
        abi.encodePacked(
          '"COLOR X',
          Strings.toString(positionX),
          ':',
          Strings.toString(positionY),
          'Y"'
        )
      );
  }

  /* 
    OWNER FUNCTIONS
     */

  function setDescription(string memory _description) public onlyOwner {
    description = _description;
  }
}

/* G */

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
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