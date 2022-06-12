// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./BaseMinter.sol";

contract DutchMintAuthorizer is BaseMinter {
  uint256 private immutable _userMintLimit;
  mapping(address => uint256) private _userMintCount;

  uint256 private immutable _startPrice;
  uint256 private immutable _endPrice;

  constructor(
    address entryPoint,
    string memory mintName,
    uint256 totalMintLimit,
    uint256 userMintLimit,
    uint256 startPrice,
    uint256 endPrice,
    uint256 startTime,
    uint256 endTime
  ) BaseMinter(entryPoint, mintName, totalMintLimit, startTime, endTime) {
    require(startPrice > endPrice);

    _userMintLimit = userMintLimit;
    _startPrice = startPrice;
    _endPrice = endPrice;
  }

  function getProofRequired() external pure override returns (bool) {
    return false;
  }

  function _getUserMintPrice() internal view returns (uint256) {
    if (block.timestamp > _endTime) {
      return _endPrice;
    } else if (block.timestamp >= _startTime) {
      uint256 duration = _endTime - _startTime;
      uint256 discount = _startPrice - _endPrice;
      uint256 elapsed = block.timestamp - _startTime;
      return _startPrice - ((discount * elapsed) / duration);
    } else {
      return _startPrice;
    }
  }

  function getUserMintPrice(address, bytes32[] memory) public view override returns (uint256) {
    return _getUserMintPrice();
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
    bytes32[] memory
  ) external override {
    _authorizeMint(number);

    uint256 newMintCount = _userMintCount[sender] + number;
    require(newMintCount <= _userMintLimit, "Trying to mint more than allowed");
    _userMintCount[sender] = newMintCount;

    require(value >= _getUserMintPrice() * number, "Insufficient payment");
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