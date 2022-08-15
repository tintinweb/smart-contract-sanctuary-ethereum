// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.16;

/*
  It saves bytecode to revert on custom errors instead of using require
  statements. We are just declaring these errors for reverting with upon various
  conditions later in this contract.
*/
error CreationFailedCheckConstructor();
error FailedToDeployContract();

/**
  @title An unsafe variant of a factory for deploying contracts to predetermined
    addresses.
  @author Tim Clancy

  This is a variant of the `ContractFactory` (which was inspired by 0age's
  Pr000xy `Create2Factory` and miguelm's `Factory`) that does not feature
  protections against submitted salts being front-ran.
  https://github.com/0age/Pr000xy/
  https://github.com/miguelmota/solidity-create2-example/

  The intent of dropping salt safety is to allow callers to use salts that were
  generated from external contexts unaware of the salt protection scheme for use
  in non-critical applications (such as deploying vanity addresses) where loss
  of funds is not possible.

  @custom:date August 14th, 2022.
*/
contract UnsafeContractFactory {

  /**
    An event emitted when a contract is deployed using this factory.

    @param destination The address at which the new contract has been deployed.
    @param bytecode The bytecode of the newly-deployed contract.
    @param salt The salt used to create the contract at `destination`.
  */
  event Deployed (
    address indexed destination,
    bytes bytecode,
    bytes32 indexed salt
  );

  /**
    Deploy a new contract with bytecode `_bytecode` to a predetermined address
    using the salt `_salt`. There is no front-running protection on the salt.
    Use with caution.

    @param _bytecode The bytecode of a new contract to deploy. This is the
      bytecode of the contract itself followed by its appended constructor
      arguments.
    @param _salt The salt which determines the address where the new contract is
      deployed to. There is no front-running protection on the salt.

    @return The destination address of newly-deployed contract.
    @custom:reverts Reverts if the contract fails to deploy to the destination.
  */
  function unsafeDeploy (
    bytes memory _bytecode,
    bytes32 _salt
  ) external payable returns (address) {
    address destination;

    // Create the new contract at `destination`, passing along any value.
    uint256 destinationSize;
    assembly {
      destination := create2(
        callvalue(),
        add(_bytecode, 0x20),
        mload(_bytecode),
        _salt
      )
      destinationSize := extcodesize(destination)
    }

    /*
      Revert if the destination size is zero; a likely candidate for this
      problem is sending value to a non-payable constructor.
    */
    if (destinationSize == 0) {
      revert CreationFailedCheckConstructor();
    }

    // Revert if the destination is the known-invalid zero address.
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
      deployed to.

    @return The destination address of create2's output contract and whether or
      not such a contract already exists.
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
              hex"FF",
              address(this),
              _salt,
              keccak256(_bytecode)
            )
          )
        )
      )
    );

    // Return the destination and whether or not a contract already exists.
    uint256 destinationSize;
    assembly {
      destinationSize := extcodesize(destination)
    }
    return (destination, destinationSize > 0);
  }
}