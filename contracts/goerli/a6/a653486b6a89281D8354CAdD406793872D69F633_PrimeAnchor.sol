// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { Base } from "../common/Base.sol";

contract PrimeAnchor is Base {
  // struct
  struct Proofs {
    uint256 startBlock;
    uint256 endBlock;
    bytes32 txnRoot;
    bytes32 stateRoot;
    bytes32 cid;
  }

  // vars
  mapping(uint256 => Proofs) public proofs;
  uint256 public currentIndex;

  // events
  event ProofPublished(uint256 indexed idx, Proofs proofsBatch);

  function publishProof(
    uint256 _startBlock,
    uint256 _endBlock,
    bytes32 _txnRoot,
    bytes32 _stateRoot,
    bytes32 _cid
  ) public onlyRole("publishProof") {
    require(_endBlock >= _startBlock, "Invalid blocks range");
    if (currentIndex > 0) {
      uint256 previousEndBlock = proofs[currentIndex - 1].endBlock;
      require(_startBlock == previousEndBlock + 1, "Blocks range mismatch");
    }

    Proofs memory proofsBatch = Proofs({
      startBlock: _startBlock, //
      endBlock: _endBlock,
      txnRoot: _txnRoot,
      stateRoot: _stateRoot,
      cid: _cid
    });

    proofs[currentIndex] = proofsBatch;
    emit ProofPublished(currentIndex, proofsBatch);
    currentIndex++;
  }

  function publishProofs(
    uint256[] calldata _startBlocks,
    uint256[] calldata _endBlocks,
    bytes32[] calldata _txnRoots,
    bytes32[] calldata _stateRoots,
    bytes32[] calldata _cids
  ) public onlyRole("publishProofs") {
    require(_txnRoots.length == _stateRoots.length, "Input mismatch");
    require(_txnRoots.length == _cids.length, "Input mismatch");

    uint256 size = _txnRoots.length;
    for (uint256 i; i < size; i++) {
      publishProof(_startBlocks[i], _endBlocks[i], _txnRoots[i], _stateRoots[i], _cids[i]);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

// Pellar + LightLink 2022

abstract contract Base is Ownable {
  // variable
  address public accessControlProvider = 0x713995e41F9687C015D5dD7e542a5354759C8800;

  constructor() {}

  // verified
  modifier onlyRole(string memory _methodInfo) {
    require(_msgSender() == owner() || IAccessControl(accessControlProvider).hasRole(_msgSender(), address(this), _methodInfo), "Caller does not have permission");
    _;
  }

  // verified
  function setAccessControlProvider(address _contract) external onlyRole("setAccessControlProvider") {
    accessControlProvider = _contract;
  }
}

interface IAccessControl {
  function hasRole(
    address _account,
    address _contract,
    string memory _methodInfo
  ) external view returns (bool);
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