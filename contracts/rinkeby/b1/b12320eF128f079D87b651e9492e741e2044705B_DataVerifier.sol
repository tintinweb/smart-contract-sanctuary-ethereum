// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";

contract DataVerifier is ConfirmedOwner {
  mapping(bytes32 => bytes32) hashes;

  constructor() ConfirmedOwner(msg.sender) {
  }

  function getDataHash
  (string memory key,
   string memory subkey1,
   string memory subkey2,
   int256 data) public pure returns (bytes32) {
     return keccak256(abi.encodePacked(key, subkey1, subkey2, data));
   }

  function getKeyHash
  (string memory key,
   string memory subkey1,
   string memory subkey2) public pure returns (bytes32) {
     return keccak256(abi.encodePacked(key, subkey1, subkey2));
   }

  function addData (
    bytes32 keyHash,
    bytes32 dataHash) public onlyOwner {
    hashes[keyHash] = dataHash;
   }

  function verifyData(
    string memory key,
    string memory subkey1,
    string memory subkey2,
    int256 data) public view returns(int256) {
      bytes32 keyhash = getKeyHash(key, subkey1, subkey2);
      bytes32 savedHash = hashes[keyhash];
      if (savedHash == 0x0) {
         return 2;
      }
      bytes32 dataHash = getDataHash(key, subkey1, subkey2, data);
      if (dataHash != savedHash) {
         return 1;
      }
      return 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ConfirmedOwnerWithProposal.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/OwnableInterface.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is OwnableInterface {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /**
   * @notice Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership() external override {
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner() public view override returns (address) {
    return s_owner;
  }

  /**
   * @notice validate, transfer ownership, and emit relevant events
   */
  function _transferOwnership(address to) private {
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /**
   * @notice validate access
   */
  function _validateOwnership() internal view {
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /**
   * @notice Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OwnableInterface {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}