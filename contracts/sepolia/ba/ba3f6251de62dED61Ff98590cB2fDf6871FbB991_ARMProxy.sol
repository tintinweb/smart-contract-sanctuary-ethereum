// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.19;

import {TypeAndVersionInterface} from "../interfaces/TypeAndVersionInterface.sol";
import {IARM} from "./interfaces/IARM.sol";

import {OwnerIsCreator} from "./../shared/access/OwnerIsCreator.sol";

contract ARMProxy is OwnerIsCreator, TypeAndVersionInterface {
  error ZeroAddressNotAllowed();

  event ARMSet(address arm);

  // STATIC CONFIG
  // solhint-disable-next-line chainlink-solidity/all-caps-constant-storage-variables
  string public constant override typeAndVersion = "ARMProxy 1.0.0";

  // DYNAMIC CONFIG
  address private s_arm;

  constructor(address arm) {
    setARM(arm);
  }

  /// @notice SetARM sets the ARM implementation contract address.
  /// @param arm The address of the arm implementation contract.
  function setARM(address arm) public onlyOwner {
    if (arm == address(0)) revert ZeroAddressNotAllowed();
    s_arm = arm;
    emit ARMSet(arm);
  }

  /// @notice getARM gets the ARM implementation contract address.
  /// @return arm The address of the arm implementation contract.
  function getARM() external view returns (address) {
    return s_arm;
  }

  // We use a fallback function instead of explicit implementations of the functions
  // defined in IARM.sol to preserve compatibility with future additions to the IARM
  // interface. Calling IARM interface methods in ARMProxy should be transparent, i.e.
  // their input/output behaviour should be identical to calling the proxied s_arm
  // contract directly. (If s_arm doesn't point to a contract, we always revert.)
  fallback() external {
    address arm = s_arm;
    assembly {
      // Revert if no contract present at destination address, otherwise call
      // might succeed unintentionally.
      if iszero(extcodesize(arm)) {
        revert(0, 0)
      }
      // We use memory starting at zero, overwriting anything that might already
      // be stored there. This messes with Solidity's expectations around memory
      // layout, but it's fine because we always exit execution of this contract
      // inside this assembly block, i.e. we don't cede control to code generated
      // by the Solidity compiler that might have expectations around memory
      // layout.
      // Copy calldatasize() bytes from calldata offset 0 to memory offset 0.
      calldatacopy(0, 0, calldatasize())
      // Call the underlying ARM implementation. out and outsize are 0 because
      // we don't know the size yet. We hardcode value to zero.
      let success := call(gas(), arm, 0, 0, calldatasize(), 0, 0)
      // Copy the returned data.
      returndatacopy(0, 0, returndatasize())
      // Pass through successful return or revert and associated data.
      if success {
        return(0, returndatasize())
      }
      revert(0, returndatasize())
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract TypeAndVersionInterface {
  function typeAndVersion() external pure virtual returns (string memory);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

/// @notice This interface contains the only ARM-related functions that might be used on-chain by other CCIP contracts.
interface IARM {
  /// @notice A Merkle root tagged with the address of the commit store contract it is destined for.
  struct TaggedRoot {
    address commitStore;
    bytes32 root;
  }

  /// @notice Callers MUST NOT cache the return value as a blessed tagged root could become unblessed.
  function isBlessed(TaggedRoot calldata taggedRoot) external view returns (bool);

  /// @notice When the ARM is "cursed", CCIP pauses until the curse is lifted.
  function isCursed() external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ConfirmedOwner} from "../../ConfirmedOwner.sol";

/// @title The OwnerIsCreator contract
/// @notice A contract with helpers for basic contract ownership.
contract OwnerIsCreator is ConfirmedOwner {
  constructor() ConfirmedOwner(msg.sender) {}
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