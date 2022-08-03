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

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface IDefaultReverseResolver {
  function name(bytes32 input) external view returns (string calldata);
}

pragma solidity >=0.8.4;

interface IReverseRegistrar {
  function setDefaultResolver(address resolver) external;

  function claim(address owner) external returns (bytes32);

  function claimForAddr(
    address addr,
    address owner,
    address resolver
  ) external returns (bytes32);

  function claimWithResolver(address owner, address resolver) external returns (bytes32);

  function setName(string memory name) external returns (bytes32);

  function setNameForAddr(
    address addr,
    address owner,
    address resolver,
    string memory name
  ) external returns (bytes32);

  function node(address addr) external pure returns (bytes32);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

interface ITextResolver {
  event TextChanged(bytes32 indexed node, string indexed indexedKey, string key);

  /**
   * Returns the text data associated with an ENS node and key.
   * @param node The ENS node to query.
   * @param key The text data key to query.
   * @return The associated text data.
   */
  function text(bytes32 node, string calldata key) external view returns (string memory);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IStream {
  function count(address _address) external view returns (uint256);

  function getData(address _address)
    external
    view
    returns (string[] memory keys, string[] memory values);

  function getValue(address _address, string memory _key) external view returns (string memory);
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { NameEncoder } from "../libraries/NameEncoder.sol";
import { IStream } from "../interfaces/IStream.sol";
import { IReverseRegistrar } from "../interfaces/ENS/IReverseRegistrar.sol";
import { ITextResolver } from "../interfaces/ENS/ITextResolver.sol";
import { IDefaultReverseResolver } from "../interfaces/ENS/IDefaultReverseResolver.sol";

contract StreamENS is IStream, Ownable {
  using NameEncoder for string;

  string[] private _keys;
  address private constant RESOLVER = 0x4976fb03C32e5B8cfe2b6cCB31c09Ba78EBaBa41;
  address private constant REVERSE_REGISTRAR = 0x084b1c3C81545d370f3634392De611CaaBFf8148;
  address private constant DEFAULT_REVERSE_RESOLVER = 0xA2C122BE93b0074270ebeE7f6b7292C7deB45047;

  constructor() {
    _keys.push("url");
    _keys.push("avatar");
    _keys.push("description");
    _keys.push("com.discord");
    _keys.push("com.github");
    _keys.push("com.twitter");
    _keys.push("eth.ens.delegate");
  }

  /* ===================================================================================== */
  /* External Functions                                                                    */
  /* ===================================================================================== */

  /**
   * @notice Get Keys
   * @return keys string[]
   */
  function getKeys() external view returns (string[] memory keys) {
    return _keys;
  }

  /**
   * @notice Get data fields count for user
   * @return count uint256
   */
  function count(address user) external view returns (uint256 count) {
    (, bytes32 node_, ITextResolver res_) = _resolveOwner(user);
    (string[] memory keys_, ) = _fetchNodeTextFields(_keys, node_, res_);
    return keys_.length;
  }

  /**
   * @notice Get all available data for user
   * @param user address
   * @return keys string[]
   * @return values string[]
   */
  function getData(address user)
    external
    view
    returns (string[] memory keys, string[] memory values)
  {
    (, bytes32 node_, ITextResolver res_) = _resolveOwner(user);
    (string[] memory keys_, string[] memory values_) = _fetchNodeTextFields(_keys, node_, res_);
    return (keys_, values_);
  }

  function getMetadata(address _address)
    external
    view
    returns (
      bytes32 node,
      string memory name,
      address resolver
    )
  {
    (string memory name, bytes32 node, ITextResolver resolver) = _resolveOwner(_address);
    return (node, name, address(resolver));
  }

  /**
   * @notice Get data value for user
   * @param user address
   * @param key string
   * @return value string
   */
  function getValue(address user, string memory key) external view returns (string memory) {
    (, bytes32 node_, ITextResolver res_) = _resolveOwner(user);
    return res_.text(node_, key);
  }

  /**
   * @notice Append Key
   * @param key string
   */
  function appendKey(string calldata key) external onlyOwner {
    _keys.push(key);
  }

  /**
   * @notice Set Key
   * @param idx uint256
   * @param key string
   */
  function updateKey(uint256 idx, string calldata key) external onlyOwner {
    _keys[idx] = key;
  }

  /* ===================================================================================== */
  /* Internal Functions                                                                    */
  /* ===================================================================================== */

  function _resolveOwner(address owner_)
    internal
    view
    returns (
      string memory,
      bytes32,
      ITextResolver
    )
  {
    bytes32 node_ = IReverseRegistrar(REVERSE_REGISTRAR).node(owner_);
    string memory _name = IDefaultReverseResolver(DEFAULT_REVERSE_RESOLVER).name(node_);
    (, bytes32 _node) = _name.dnsEncodeName();
    ITextResolver _resolver = ITextResolver(RESOLVER);
    return (_name, _node, _resolver);
  }

  function _fetchNodeTextFields(
    string[] memory _traits,
    bytes32 _node,
    ITextResolver _resolver
  ) internal view returns (string[] memory keys_, string[] memory values_) {
    string[] memory __keys = new string[](_traits.length);
    string[] memory __values = new string[](_traits.length);
    for (uint256 i = 0; i < _traits.length; i++) {
      __keys[i] = _traits[i];
      __values[i] = _resolver.text(_node, _traits[i]);
    }
    return (__keys, __values);
  }
}