// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./BaseMinter.sol";

contract MerkleMintAuthorizer is BaseMinter {
  uint256 private immutable _userMintLimit;
  mapping(address => uint256) private _userMintCount;

  bytes32 private immutable _merkleRoot;
  uint256 private immutable _userMintPrice;

  constructor(
    address entryPoint,
    string memory mintName,
    uint256 totalMintLimit,
    uint256 userMintLimit,
    bytes32 merkleRoot,
    uint256 userMintPrice,
    uint256 startTime,
    uint256 endTime
  ) BaseMinter(entryPoint, mintName, totalMintLimit, startTime, endTime) {
    _userMintLimit = userMintLimit;
    _merkleRoot = merkleRoot;
    _userMintPrice = userMintPrice;
  }

  function getProofRequired() external view override returns (bool) {
    return _merkleRoot != bytes32(0);
  }

  function getUserMintPrice(address, bytes32[] memory) external view override returns (uint256) {
    return _userMintPrice;
  }

  function getUserMintLimit(address, bytes32[] memory) external view override returns (uint256) {
    return _userMintLimit;
  }

  function getUserMintCount(address user) external view override returns (uint256) {
    return _userMintCount[user];
  }

  function authorizeMint(
    address sender,
    uint256 value,
    uint256 number,
    bytes32[] memory proof
  ) external override {
    _authorizeMint(number);

    uint256 newMintCount = _userMintCount[sender] + number;
    require(newMintCount <= _userMintLimit, "Trying to mint more than allowed");
    _userMintCount[sender] = newMintCount;

    require(_merkleRoot == bytes32(0) || MerkleProof.verify(
              proof, _merkleRoot, keccak256(abi.encodePacked(sender))),
            "Merkle proof failed");

    // We can't use "Insufficient funds" because ethers-io makes
    // some assumptions about specific error strings and throws an error
    // when it sees one...
    //   see: https://github.com/NomicFoundation/hardhat/issues/2489
    require(value >= _userMintPrice * number, "Insufficient payment");
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/introspection/ERC165Storage.sol";

import "./IRebelsMintAuthorizer.sol";
import "./IRebelsMintInfo.sol";

abstract contract BaseMinter is IRebelsMintAuthorizer, IRebelsMintInfo, ERC165Storage {
  address private immutable _entryPoint;
  string private _mintName;

  uint256 internal immutable _totalMintLimit;
  uint256 internal _totalMintCount;

  uint256 internal immutable _startTime;
  uint256 internal immutable _endTime;

  constructor(
    address entryPoint,
    string memory mintName,
    uint256 totalMintLimit,
    uint256 startTime,
    uint256 endTime
  ) {
    require(startTime < endTime);

    _entryPoint = entryPoint;
    _mintName = mintName;
    _totalMintLimit = totalMintLimit;
    _startTime = startTime;
    _endTime = endTime;

    _registerInterface(type(IRebelsMintAuthorizer).interfaceId);
    _registerInterface(type(IRebelsMintInfo).interfaceId);
  }

  function getMintName() external view override returns (string memory) {
    return _mintName;
  }

  function getMintActive() public view override returns (bool) {
    return _startTime <= block.timestamp && block.timestamp < _endTime;
  }

  function getMintStartTime() external view override returns (uint256) {
    return _startTime;
  }

  function getMintEndTime() external view override returns (uint256) {
    return _endTime;
  }

  function getTotalMintLimit() external view override returns (uint256) {
    return _totalMintLimit;
  }

  function getTotalMintCount() external view override returns (uint256) {
    return _totalMintCount;
  }

  function _authorizeMint(
    uint256 number
  ) internal {
    require(msg.sender == _entryPoint);

    require(getMintActive(), "Mint is not active");

    uint256 newTotalMintCount = _totalMintCount + number;
    require(newTotalMintCount <= _totalMintLimit,
            "Trying to mint more than total allowed");
    _totalMintCount = newTotalMintCount;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Storage.sol)

pragma solidity ^0.8.0;

import "./ERC165.sol";

/**
 * @dev Storage based implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165Storage is ERC165 {
    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return super.supportsInterface(interfaceId) || _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IRebelsMintAuthorizer {
  function authorizeMint(
    address sender,
    uint256 value,
    uint256 number,
    bytes32[] memory senderData
  ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IRebelsMintInfo {
  function getMintName() external view returns (string memory);
  function getMintActive() external view returns (bool);
  function getMintStartTime() external view returns (uint256);
  function getMintEndTime() external view returns (uint256);

  function getProofRequired() external view returns (bool);
  function getTotalMintLimit() external view returns (uint256);
  function getTotalMintCount() external view returns (uint256);

  function getUserMintPrice(address user, bytes32[] memory senderData) external view returns (uint256);
  function getUserMintLimit(address user, bytes32[] memory senderData) external view returns (uint256);
  function getUserMintCount(address user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}