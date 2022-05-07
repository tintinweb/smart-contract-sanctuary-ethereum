//	SPDX-License-Identifier: MIT
/// @title  Logo Nft Descriptor
/// @notice Descriptor which allow configuratin of logo nft
pragma solidity ^0.8.0;

import './common/LogoHelper.sol';
import './common/LogoModel.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract LogoNftDescriptor is Ownable {
  /// @notice Permanently seals the contract from being modified by owner
  bool public contractSealed;

  string public namePrefix = 'DO NOT PURCHASE. Logo Container #'; 
  string public description = 'DO NOT PURCHASE. Logo containers point to other NFTs to create an image.'
                              ' Purchasing this NFT will not also purchase the NFTs creating the image.'
                              ' There is an infinite supply of logo containers and they can be minted for free.';

  modifier onlyWhileUnsealed() {
    require(!contractSealed, 'Contract is sealed');
    _;
  }

  constructor() Ownable() {}

  /// @notice Sets the prefix of a logo container name used by tokenURI
  /// @param _namePrefix, prefix to use for the logo container
  function setNamePrefix(string memory _namePrefix) external onlyOwner onlyWhileUnsealed {
    namePrefix = _namePrefix;
  }

  /// @notice Sets the description of a logo container name used by tokenUri
  /// @param _description, description to use for the logo container
  function setDescription(string memory _description) external onlyOwner onlyWhileUnsealed {
    description = _description;
  }

  /// @notice Gets attributes for attributes used in tokenURI
  function getAttributes(Model.Logo memory logo) public view returns (string memory) {
    string memory attributes;
    for (uint i; i < logo.layers.length; i++) {
      attributes = string(abi.encodePacked(attributes, '{"trait_type": "Layer #', LogoHelper.toString(i), ' Address", "value": "0x', LogoHelper.toString(logo.layers[i].contractAddress), '"}, '));
      attributes = string(abi.encodePacked(attributes, '{"trait_type": "Layer #', LogoHelper.toString(i),  ' Token Id", "value": "', LogoHelper.toString(logo.layers[i].tokenId), '"}, '));
    }
    attributes = string(abi.encodePacked(attributes, '{"trait_type": "Text Address", "value": "0x', LogoHelper.toString(logo.text.contractAddress), '"}, '));
    attributes = string(abi.encodePacked('[', attributes, '{"trait_type": "Text Token Id", "value": "', LogoHelper.toString(logo.text.tokenId), '"}]'));
    return attributes;
  }

  /// @notice Permananetly seals the contract from being modified
  function sealContract() external onlyOwner {
    contractSealed = true;
  }
}

//	SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


library LogoHelper {
  function getRotate(string memory text) public pure returns (string memory) {
    bytes memory byteString = bytes(text);
    string memory rotate = string(abi.encodePacked('-', toString(random(text) % 10 + 1)));
    for (uint i=1; i < byteString.length; i++) {
      uint nextRotate = random(rotate) % 10 + 1;
      if (i % 2 == 0) {
        rotate = string(abi.encodePacked(rotate, ',-', toString(nextRotate)));
      } else {
        rotate = string(abi.encodePacked(rotate, ',', toString(nextRotate)));
      }
    }
    return rotate;
  }

  function getTurbulance(string memory seed, uint max, uint magnitudeOffset) public pure returns (string memory) {
    string memory turbulance = decimalInRange(seed, max, magnitudeOffset);
    uint rand = randomInRange(turbulance, max, 0);
    return string(abi.encodePacked(turbulance, ', ', getDecimal(rand, magnitudeOffset)));
  }

  function decimalInRange(string memory seed, uint max, uint magnitudeOffset) public pure returns (string memory) {
    uint rand = randomInRange(seed, max, 0);
    return getDecimal(rand, magnitudeOffset);
  }

  // CORE HELPERS //
  function random(string memory input) public pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(input)));
  }

  function randomFromInt(uint256 seed) internal pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(seed)));
  }

  function randomInRange(string memory input, uint max, uint offset) public pure returns (uint256) {
    max = max - offset;
    return (random(input) % max) + offset;
  }

  function equal(string memory a, string memory b) public pure returns (bool) {
    return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
  }

  function toString(uint256 value) public pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
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

  function toString(address x) internal pure returns (string memory) {
    bytes memory s = new bytes(40);
    for (uint i = 0; i < 20; i++) {
      bytes1 b = bytes1(uint8(uint(uint160(x)) / (2**(8*(19 - i)))));
      bytes1 hi = bytes1(uint8(b) / 16);
      bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
      s[2*i] = char(hi);
      s[2*i+1] = char(lo);            
    }
    return string(s);
  }

function char(bytes1 b) internal pure returns (bytes1 c) {
  if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
  else return bytes1(uint8(b) + 0x57);
}
  
  function getDecimal(uint val, uint magnitudeOffset) public pure returns (string memory) {
    string memory decimal;
    if (val != 0) {
      for (uint i = 10; i < magnitudeOffset / val; i=10*i) {
        decimal = string(abi.encodePacked(decimal, '0'));
      }
    }
    decimal = string(abi.encodePacked('0.', decimal, toString(val)));
    return decimal;
  }

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

//	SPDX-License-Identifier: MIT
/// @notice Definition of Logo model
pragma solidity ^0.8.0;

library Model {

  /// @notice A logo container which holds layers of composable visual onchain assets
  struct Logo {
    uint16 width;
    uint16 height;
    LogoElement[] layers;
    LogoElement text;
  }

  /// @notice A layer of a logo displaying a visual onchain asset
  struct LogoElement {
    address contractAddress;
    uint32 tokenId;
    uint8 translateXDirection;
    uint16 translateX;
    uint8 translateYDirection;
    uint16 translateY;
    uint8 scaleDirection;
    uint8 scaleMagnitude;
  }

  /// @notice Data that can be set by logo owners and can be used in a composable onchain manner
  struct MetaData {
    string key;
    string value;
  }
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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