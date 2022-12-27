// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { IVestingEscrow } from "./interfaces/IVestingEscrow.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Clones } from "@openzeppelin/contracts/proxy/Clones.sol";

/**
 * @title VestingEscrowFactory
 * @author BootNode
 * @dev Deploy VestingEscrow proxy contracts to distribute ERC20 tokens and acts as a beacon contract to determine
 * their implementation contract.
 */
contract VestingEscrowFactory {
  using Clones for address;

  /**
   * @dev Struct used to group escrow related data used in `deployVestingEscrow` function
   *
   * `recipient` The address of the recipient that will be receiving the tokens
   * `admin` The address of the admin that will have special execution permissions in the escrow contract.
   * `vestingAmount` Amount of tokens being vested for `recipient`
   * `vestingBegin` Epoch time when tokens begin to vest
   * `vestingCliff` Duration after which the first portion vests
   * `vestingEnd` Epoch Time until all the amount should be vested
   */
  struct EscrowParams {
    address recipient;
    address admin;
    address token;
    uint256 vestingAmount;
    uint256 vestingBegin;
    uint256 vestingCliff;
    uint256 vestingEnd;
  }

  struct Escrow {
    address deployer;
    address token;
    address recipient;
    address admin;
    address escrow;
    uint256 amount;
    uint256 vestingBegin;
    uint256 vestingCliff;
    uint256 vestingEnd;
  }

  address public implementation;
  Escrow[] public escrows;

  event VestingEscrowCreated(
    address indexed deployer,
    address indexed token,
    address indexed recipient,
    address admin,
    address escrow,
    uint256 amount,
    uint256 vestingBegin,
    uint256 vestingCliff,
    uint256 vestingEnd
  );

  /**
   * @dev Stores the implementation target for the proxies.
   *
   * @param implementation_ The address of the target implementation
   */
  constructor(address implementation_) {
    implementation = implementation_;
  }

  /**
   * @dev Deploys a proxy, initialize the vesting data and fund the escrow contract.
   * Caller should previously give allowance of the token.
   *
   * @param escrowData Escrow related data
   * @return The address of the deployed contract
   */
  function deployVestingEscrow(EscrowParams memory escrowData) external returns (address) {
    // Create the escrow contract
    address vestingEscrow = implementation.clone();

    // Initialize the contract with the vesting data
    require(
      IVestingEscrow(vestingEscrow).initialize(
        escrowData.token,
        escrowData.recipient,
        escrowData.vestingAmount,
        escrowData.vestingBegin,
        escrowData.vestingCliff,
        escrowData.vestingEnd
      ),
      "initialization failed"
    );

    // Transfer the ownership to the admin
    IVestingEscrow(vestingEscrow).transferOwnership(escrowData.admin);

    // Transfer funds from the caller to the escrow contract
    IERC20(escrowData.token).transferFrom(msg.sender, vestingEscrow, escrowData.vestingAmount);

    escrows.push(
      Escrow(
        msg.sender,
        escrowData.token,
        escrowData.recipient,
        escrowData.admin,
        vestingEscrow,
        escrowData.vestingAmount,
        escrowData.vestingBegin,
        escrowData.vestingCliff,
        escrowData.vestingEnd
      )
    );

    emit VestingEscrowCreated(
      msg.sender,
      escrowData.token,
      escrowData.recipient,
      escrowData.admin,
      vestingEscrow,
      escrowData.vestingAmount,
      escrowData.vestingBegin,
      escrowData.vestingCliff,
      escrowData.vestingEnd
    );

    return vestingEscrow;
  }

  function getEscrows() external view returns (Escrow[] memory) {
    Escrow[] memory list = new Escrow[](escrows.length);

    for (uint256 i = 0; i < escrows.length; i++) {
      list[i] = escrows[i];
    }

    return list;
  }

  function getEscrowsByRecipient(address recipient) external view returns (Escrow[] memory) {
    Escrow[] memory tempList = new Escrow[](escrows.length);

    uint256 j = 0;

    for (uint256 i = 0; i < escrows.length; i++) {
      if (escrows[i].recipient == recipient) {
        tempList[j] = escrows[i];
        j++;
      }
    }

    Escrow[] memory list = new Escrow[](j);

    for (uint256 i = 0; i < j; i++) {
      list[i] = tempList[j];
    }

    return list;
  }

  function getEscrowsByDeployer(address deployer) external view returns (Escrow[] memory) {
    Escrow[] memory tempList = new Escrow[](escrows.length);

    uint256 j = 0;

    for (uint256 i = 0; i < escrows.length; i++) {
      if (escrows[i].deployer == deployer) {
        tempList[j] = escrows[i];
        j++;
      }
    }

    Escrow[] memory list = new Escrow[](j);

    for (uint256 i = 0; i < j; i++) {
      list[i] = tempList[j];
    }

    return list;
  }

  function getEscrowsByAdmin(address admin) external view returns (Escrow[] memory) {
    Escrow[] memory tempList = new Escrow[](escrows.length);

    uint256 j = 0;

    for (uint256 i = 0; i < escrows.length; i++) {
      if (escrows[i].admin == admin) {
        tempList[j] = escrows[i];
        j++;
      }
    }

    Escrow[] memory list = new Escrow[](j);

    for (uint256 i = 0; i < j; i++) {
      list[i] = tempList[j];
    }

    return list;
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IVestingEscrow {
  function initialize(
    address token,
    address recipient,
    uint256 vestingAmount,
    uint256 vestingBegin,
    uint256 vestingCliff,
    uint256 vestingEnd
  ) external returns (bool);

  function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}