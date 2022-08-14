// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.16;

import "@openzeppelin/contracts/utils/Context.sol";

/*
  It saves bytecode to revert on custom errors instead of using require
  statements. We are just declaring these errors for reverting with upon various
  conditions later in this contract.
*/
error InvalidSaltSender();
error FailedToDeployContract();

/**
  @title A factory for deploying contracts to predetermined addresses.
  @author Tim Clancy

  This is a modified take on a contract deployment factory inspired by 0age's
  Pr000xy `Create2Factory` and miguelm's `Factory`.
  https://github.com/0age/Pr000xy/
  https://github.com/miguelmota/solidity-create2-example/

  August 13th, 2022.
*/
contract ContractFactory is
  Context
{

  /**
    An event emitted when a contract is deployed using this factory.

    @param destination The address at which the new contract has been deployed.
    @param bytecode The bytecode of the newly-deployed contract.
    @param salt The salt used in the call to create the contract at `address`.
  */
  event Deployed (
    address indexed destination,
    bytes indexed bytecode,
    bytes32 indexed salt
  );

  /**
    Deploy a new contract with bytecode `_bytecode` to a predetermined address
    using the salt `_salt`.

    @param _bytecode The bytecode of a new contract to deploy.
    @param _salt The salt which determines the address where the new contract is
      deployed to. To mitigate front-runners being able to intercept this salt
      and potentially snipe the deployment of predetermined contracts, the first
      20 bytes of this `_salt` must be equal to the message sender.

    @return The destination address of newly-deployed contract.
    @custom:reverts Reverts if the salt encodes an address that is not the
      caller. Reverts if the contract fails to deploy to the destination.
  */
  function deploy (
    bytes memory _bytecode,
    bytes32 _salt
  ) external payable returns (address) {
    address destination;

    /*
      Protect against front-runners intercepting the `_salt` by requiring that
      the first 20 bytes of the `_salt` be the address of the message sender.
      Revert if this is not the case.
    */
    if (bytes20(_salt) != bytes20(_msgSender())) {
      revert InvalidSaltSender();
    }

    // Create the new contract at `destination`, passing along any value.
    assembly {
      destination := create2(
        callvalue(),
        add(_bytecode, 0x20),
        mload(_bytecode),
        _salt
      )
      if iszero(extcodesize(destination)) {
        revert(0, 0)
      }
    }

    // Revert if the destination is the invalid zero address.
    if (destination == address(0)) {
      revert FailedToDeployContract();
    }

    // Emit an event.
    emit Deployed(destination, _bytecode, _salt);

    // Return the newly-deployed contract's destination address.
    return destination;
  }

  /**
    Check the destination address that would result from the deployment of the
    contract with `_bytecode` using the specific salt `_salt`. Also return
    whether or not a contract already exists at the desired address.

    @param _bytecode The bytecode of a new contract deployment. This is the
      bytecode of the contract itself followed by its appended constructor
      arguments.
    @param _salt The salt which determines the address where the new contract is
      deployed to. To mitigate front-runners being able to intercept this salt
      and potentially snipe the deployment of predetermined contracts, the first
      20 bytes of this `_salt` must be equal to the message sender.

    @return The destination address of to-be-deployed contract.
  */
  function checkDestinationAddress (
    bytes memory _bytecode,
    bytes32 _salt
  ) external view returns (address, bool) {

    /*
      Compute the predetermined contract deployment address using the same
      formula used by the `create2` operation:
      `keccak256(0xFF, address(this), _salt, keccak256(_bytecode))[12:]`.
    */
    address destination = address(
      uint160(
        uint256(
          keccak256(
            abi.encodePacked(
              "0xFF",
              address(this),
              _salt,
              keccak256(_bytecode)
            )
          )
        )
      )
    );

    // Return whether a contract already exists at the destination.
    uint256 destinationSize;
    assembly {
      destinationSize := extcodesize(destination)
    }
    return (destination, destinationSize > 0);
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