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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { NameEncoder } from "./libraries/NameEncoder.sol";
import { IENSReverseRecords } from "./interfaces/IENSReverseRecords.sol";
import { INounsDescriptor } from "./interfaces/INounsDescriptor.sol";
import { INounsSeeder } from "./interfaces/INounsSeeder.sol";

contract ENounsRender is Ownable {
  using NameEncoder for string;

  string private constant ENCODING = "data:image/svg+xml;base64,";

  /// @notice NounsDescriptor instance
  address private immutable _nounsDescriptor;

  /// @notice ENSReverseRecords instance
  address private immutable _ensReverseRecords;

  constructor(address nounsDescriptor, address ensReverseRecords) public {
    _nounsDescriptor = nounsDescriptor;
    _ensReverseRecords = ensReverseRecords;
  }

  /* ===================================================================================== */
  /* External Functions                                                                    */
  /* ===================================================================================== */

  function render(bytes memory input) external view returns (string memory) {
    bytes32 _seedEntropy = abi.decode(input, (bytes32));
    return
      string.concat(
        ENCODING,
        INounsDescriptor(_nounsDescriptor).generateSVGImage(_generateSeed(uint256(_seedEntropy)))
      );
  }

  function renderUsingAddress(address user) external view returns (string memory) {
    return
      string.concat(
        ENCODING,
        INounsDescriptor(_nounsDescriptor).generateSVGImage(
          _generateSeed(_generateInputFromAddress(user))
        )
      );
  }

  function renderUsingEnsName(string memory ensName) external view returns (string memory) {
    return
      string.concat(
        ENCODING,
        INounsDescriptor(_nounsDescriptor).generateSVGImage(
          _generateSeed(_generateInputFromName(ensName))
        )
      );
  }

  /* ===================================================================================== */
  /* Internal Functions                                                                    */
  /* ===================================================================================== */

  function _generateInputFromAddress(address _address) internal view returns (uint256) {
    string memory toEnsName_ = _reverseName(_address);
    return uint256(_encodeName(toEnsName_));
  }

  function _generateInputFromSeed(bytes32 _seed) internal view returns (uint256) {
    return uint256(_seed);
  }

  function _generateInputFromName(string memory _ensName) internal pure returns (uint256) {
    return uint256(_encodeName(_ensName));
  }

  function _encodeName(string memory _name) internal pure returns (bytes32) {
    (, bytes32 _node) = _name.dnsEncodeName();
    return _node;
  }

  function _reverseName(address _address) internal view returns (string memory) {
    address[] memory t = new address[](1);
    t[0] = _address;
    return IENSReverseRecords(_ensReverseRecords).getNames(t)[0];
  }

  function _generateSeed(uint256 _pseudorandomness)
    private
    view
    returns (INounsSeeder.Seed memory)
  {
    uint256 backgroundCount = INounsDescriptor(_nounsDescriptor).backgroundCount();
    uint256 bodyCount = INounsDescriptor(_nounsDescriptor).bodyCount();
    uint256 accessoryCount = INounsDescriptor(_nounsDescriptor).accessoryCount();
    uint256 headCount = INounsDescriptor(_nounsDescriptor).headCount();
    uint256 glassesCount = INounsDescriptor(_nounsDescriptor).glassesCount();

    return
      INounsSeeder.Seed({
        background: uint48(uint48(_pseudorandomness) % backgroundCount),
        body: uint48(uint48(_pseudorandomness >> 48) % bodyCount),
        accessory: uint48(uint48(_pseudorandomness >> 96) % accessoryCount),
        head: uint48(uint48(_pseudorandomness >> 144) % headCount),
        glasses: uint48(uint48(_pseudorandomness >> 192) % glassesCount)
      });
  }

  function generate(uint256 _tokenId, string memory _alias) public view returns (string memory) {
    return string("");
  }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

abstract contract IENSReverseRecords {
    function getNames(address[] calldata addresses) external view virtual returns (string[] memory r);
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for NounsDescriptor

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

import { INounsSeeder } from './INounsSeeder.sol';

interface INounsDescriptor {
    event PartsLocked();

    event DataURIToggled(bool enabled);

    event BaseURIUpdated(string baseURI);

    function arePartsLocked() external returns (bool);

    function isDataURIEnabled() external returns (bool);

    function baseURI() external returns (string memory);

    function palettes(uint8 paletteIndex, uint256 colorIndex) external view returns (string memory);

    function backgrounds(uint256 index) external view returns (string memory);

    function bodies(uint256 index) external view returns (bytes memory);

    function accessories(uint256 index) external view returns (bytes memory);

    function heads(uint256 index) external view returns (bytes memory);

    function glasses(uint256 index) external view returns (bytes memory);

    function backgroundCount() external view returns (uint256);

    function bodyCount() external view returns (uint256);

    function accessoryCount() external view returns (uint256);

    function headCount() external view returns (uint256);

    function glassesCount() external view returns (uint256);

    function addManyColorsToPalette(uint8 paletteIndex, string[] calldata newColors) external;

    function addManyBackgrounds(string[] calldata backgrounds) external;

    function addManyBodies(bytes[] calldata bodies) external;

    function addManyAccessories(bytes[] calldata accessories) external;

    function addManyHeads(bytes[] calldata heads) external;

    function addManyGlasses(bytes[] calldata glasses) external;

    function addColorToPalette(uint8 paletteIndex, string calldata color) external;

    function addBackground(string calldata background) external;

    function addBody(bytes calldata body) external;

    function addAccessory(bytes calldata accessory) external;

    function addHead(bytes calldata head) external;

    function addGlasses(bytes calldata glasses) external;

    function lockParts() external;

    function toggleDataURIEnabled() external;

    function setBaseURI(string calldata baseURI) external;

    function tokenURI(uint256 tokenId, INounsSeeder.Seed memory seed) external view returns (string memory);

    function dataURI(uint256 tokenId, INounsSeeder.Seed memory seed) external view returns (string memory);

    function genericDataURI(
        string calldata name,
        string calldata description,
        INounsSeeder.Seed memory seed
    ) external view returns (string memory);

    function generateSVGImage(INounsSeeder.Seed memory seed) external view returns (string memory);
}

// SPDX-License-Identifier: GPL-3.0

/// @title Interface for NounsSeeder

/*********************************
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░██░░░████░░██░░░████░░░ *
 * ░░██████░░░████████░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░██░░██░░░████░░██░░░████░░░ *
 * ░░░░░░█████████░░█████████░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 * ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ *
 *********************************/

pragma solidity ^0.8.6;

import { INounsDescriptor } from './INounsDescriptor.sol';

interface INounsSeeder {
    struct Seed {
        uint48 background;
        uint48 body;
        uint48 accessory;
        uint48 head;
        uint48 glasses;
    }

    function generateSeed(uint256 nounId, INounsDescriptor descriptor) external view returns (Seed memory);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

library BytesUtils {
  /*
   * @dev Returns the keccak-256 hash of a byte range.
   * @param self The byte string to hash.
   * @param offset The position to start hashing at.
   * @param len The number of bytes to hash.
   * @return The hash of the byte range.
   */
  function keccak(
    bytes memory self,
    uint256 offset,
    uint256 len
  ) internal pure returns (bytes32 ret) {
    require(offset + len <= self.length);
    assembly {
      ret := keccak256(add(add(self, 32), offset), len)
    }
  }

  /**
   * @dev Returns the ENS namehash of a DNS-encoded name.
   * @param self The DNS-encoded name to hash.
   * @param offset The offset at which to start hashing.
   * @return The namehash of the name.
   */
  function namehash(bytes memory self, uint256 offset) internal pure returns (bytes32) {
    (bytes32 labelhash, uint256 newOffset) = readLabel(self, offset);
    if (labelhash == bytes32(0)) {
      require(offset == self.length - 1, "namehash: Junk at end of name");
      return bytes32(0);
    }
    return keccak256(abi.encodePacked(namehash(self, newOffset), labelhash));
  }

  /**
   * @dev Returns the keccak-256 hash of a DNS-encoded label, and the offset to the start of the next label.
   * @param self The byte string to read a label from.
   * @param idx The index to read a label at.
   * @return labelhash The hash of the label at the specified index, or 0 if it is the last label.
   * @return newIdx The index of the start of the next label.
   */
  function readLabel(bytes memory self, uint256 idx)
    internal
    pure
    returns (bytes32 labelhash, uint256 newIdx)
  {
    require(idx < self.length, "readLabel: Index out of bounds");
    uint256 len = uint256(uint8(self[idx]));
    if (len > 0) {
      labelhash = keccak(self, idx + 1, len);
    } else {
      labelhash = bytes32(0);
    }
    newIdx = idx + len + 1;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./BytesUtils.sol";

library NameEncoder {
  using BytesUtils for bytes;

  function dnsEncodeName(string memory name)
    internal
    pure
    returns (bytes memory dnsName, bytes32 node)
  {
    uint8 labelLength = 0;
    bytes memory bytesName = bytes(name);
    uint256 length = bytesName.length;
    dnsName = new bytes(length + 2);
    node = 0;
    if (length == 0) {
      dnsName[0] = 0;
      return (dnsName, node);
    }

    // use unchecked to save gas since we check for an underflow
    // and we check for the length before the loop
    unchecked {
      for (uint256 i = length - 1; i >= 0; i--) {
        if (bytesName[i] == ".") {
          dnsName[i + 1] = bytes1(labelLength);
          node = keccak256(abi.encodePacked(node, bytesName.keccak(i + 1, labelLength)));
          labelLength = 0;
        } else {
          labelLength += 1;
          dnsName[i + 1] = bytesName[i];
        }
        if (i == 0) {
          break;
        }
      }
    }

    node = keccak256(abi.encodePacked(node, bytesName.keccak(0, labelLength)));

    dnsName[0] = bytes1(labelLength);
    return (dnsName, node);
  }
}