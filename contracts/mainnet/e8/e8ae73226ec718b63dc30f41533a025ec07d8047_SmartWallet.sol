/**
 *Submitted for verification at Etherscan.io on 2022-02-10
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

interface WalletInterface {
  event CallSuccess(
    bool rolledBack,
    address to,
    uint256 value,
    bytes data,
    bytes returnData
  );

  event CallFailure(
    address to,
    uint256 value,
    bytes data,
    string revertReason
  );

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  // Use an array of Calls for executing generic batch calls.
  struct Call {
    address to;
    uint96 value;
    bytes data;
  }

  // Use an array of CallReturns for handling generic batch calls.
  struct CallReturn {
    bool ok;
    bytes returnData;
  }

  struct ValueReplacement {
    uint24 returnDataOffset;
    uint8 valueLength;
    uint16 callIndex;
  }

  struct DataReplacement {
    uint24 returnDataOffset;
    uint24 dataLength;
    uint16 callIndex;
    uint24 callDataOffset;
  }

  struct AdvancedCall {
    address to;
    uint96 value;
    bytes data;
    ValueReplacement[] replaceValue;
    DataReplacement[] replaceData;
  }

  struct AdvancedCallReturn {
    bool ok;
    bytes returnData;
    uint96 callValue;
    bytes callData;
  }

  receive() external payable;

  function execute(
    Call[] calldata calls
  ) external returns (bool[] memory ok, bytes[] memory returnData);

  function executeAdvanced(
    AdvancedCall[] calldata calls
  ) external returns (AdvancedCallReturn[] memory callResults);

  function simulate(
    Call[] calldata calls
  ) external /* view */ returns (bool[] memory ok, bytes[] memory returnData);

  function simulateAdvanced(
    AdvancedCall[] calldata calls
  ) external /* view */ returns (AdvancedCallReturn[] memory callResults);

  function claimOwnership(address owner) external;

  function transferOwnership(address newOwner) external;

  function cancelOwnershipTransfer() external;

  function acceptOwnership() external;

  function owner() external view returns (address);

  function isOwner() external view returns (bool);

  function isValidSignature(bytes32 digest, bytes memory signature) external view returns (bytes4);

  function getImplementation() external view returns (address implementation);

  function getVersion() external pure returns (uint256 version);

  function initialize(address) external pure;
}


/**
 * @dev Library for determining if a given account is a contract.
 */
library Address {
  function isContract(address account) internal view returns (bool) {
    uint256 size;
    assembly { size := extcodesize(account) }
    return size > 0;
  }
}


/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }
}


/**
 * @notice Smart wallet supporting batch calls, EIP-1271, and call simulations.
 * In order to claim ownership of a given smart wallet, a signed message and
 * associated proof must be submitted to the "MerkleWalletClaimer" contract.
 * @author 0age
 */
contract SmartWallet is WalletInterface {
  using Address for address;

  // Skip over previously-used storage slots.
  address private __DEPRECATED_SLOT_ONE__;
  uint256 private __DEPRECATED_SLOT_TWO__;

  // The self-call context flag is in storage slot 2. Some protected functions
  // may only be called externally from calls originating from other methods on
  // this contract, which enables appropriate exception handling on reverts.
  // Any storage should only be set immediately preceding a self-call and should
  // be cleared upon entering the protected function being called.
  bytes4 internal _selfCallContext;

  // Store the current owner of the contract.
  address internal _owner;

  // Store the next potential owner of the contract.
  address internal _newPotentialOwner;

  // Only this contract may call `claimOwnership` to set the initial owner.
  address public constant merkleWalletClaimer = address(
    0xD8470a6d796d54F13f243A4cf1a890E65bF3670E
  );

  // The "upgrade beacon" tracks the current implementation contract address/
  address internal constant _UPGRADE_BEACON = address(
    0x000000000026750c571ce882B17016557279ADaa
  );

  uint256 internal constant _VERSION = 17;

  /**
   * @notice Enable receipt of Ether.
   */
  receive() external payable override {}

  /**
   * @notice Execute an atomic batch of calls.
   * Can only be called by the current owner.
   * @param calls The calls to execute.
   * @return ok The status of each call.
   * @return returnData The returndata of each call.
   */
  function execute(
    Call[] calldata calls
  ) external override onlyOwner() returns (bool[] memory ok, bytes[] memory returnData) {
    // Ensure that each `to` address is a contract and is not this contract.
    for (uint256 i = 0; i < calls.length; i++) {
      if (calls[i].value == 0) {
        _ensureValidGenericCallTarget(calls[i].to);
      }
    }

    // Note: from this point on, there are no reverts (apart from out-of-gas or
    // call-depth-exceeded) originating from this contract. However, one of the
    // calls may revert, in which case the function will return `false`, along
    // with the revert reason encoded as bytes, and fire a CallFailure event.

    // Specify length of returned values in order to work with them in memory.
    ok = new bool[](calls.length);
    returnData = new bytes[](calls.length);

    // Set self-call context to call _execute.
    _selfCallContext = this.execute.selector;

    // Make the atomic self-call - if any call fails, calls that preceded it
    // will be rolled back and calls that follow it will not be made.
    (bool externalOk, bytes memory rawCallResults) = address(this).call(
      abi.encodeWithSelector(
        this._execute.selector, calls
      )
    );

    // Ensure that self-call context has been cleared.
    if (!externalOk) {
      delete _selfCallContext;
    }

    // Parse data returned from self-call into each call result and store / log.
    CallReturn[] memory callResults = abi.decode(rawCallResults, (CallReturn[]));
    for (uint256 i = 0; i < callResults.length; i++) {
      Call memory currentCall = calls[i];

      // Set the status and the return data / revert reason from the call.
      ok[i] = callResults[i].ok;
      returnData[i] = callResults[i].returnData;

      // Emit CallSuccess or CallFailure event based on the outcome of the call.
      if (callResults[i].ok) {
        // Note: while the call succeeded, the action may still have "failed".
        emit CallSuccess(
          !externalOk, // If another call failed this will have been rolled back
          currentCall.to,
          uint256(currentCall.value),
          currentCall.data,
          callResults[i].returnData
        );
      } else {
        // Note: while the call failed, the nonce will still be incremented,
        // which will invalidate all supplied signatures.
        emit CallFailure(
          currentCall.to,
          uint256(currentCall.value),
          currentCall.data,
          _decodeRevertReason(callResults[i].returnData)
        );

        // exit early - any calls after the first failed call will not execute.
        break;
      }
    }
  }

  /**
   * @dev "Internal" helper to execute an atomic batch of calls.
   * Can only be called from this contract during a call to `execute`.
   * @param calls The calls to execute.
   * @return callResults The results of each call.
   */
  function _execute(
    Call[] calldata calls
  ) external returns (CallReturn[] memory callResults) {
    // Ensure caller is this contract and self-call context is correctly set.
    _enforceSelfCallFrom(this.execute.selector);

    bool rollBack = false;
    callResults = new CallReturn[](calls.length);

    for (uint256 i = 0; i < calls.length; i++) {
      // Perform low-level call and set return values using result.
      (bool ok, bytes memory returnData) = calls[i].to.call{
        value: uint256(calls[i].value)
      }(calls[i].data);
      callResults[i] = CallReturn({ok: ok, returnData: returnData});
      if (!ok) {
        // Exit early - any calls after the first failed call will not execute.
        rollBack = true;
        break;
      }
    }

    if (rollBack) {
      // Wrap in length encoding and revert (provide bytes instead of a string).
      bytes memory callResultsBytes = abi.encode(callResults);
      assembly { revert(add(32, callResultsBytes), mload(callResultsBytes)) }
    }
  }

  /**
   * @notice Execute an atomic batch of advanced calls (where returndata can be used to
   * populate calldata of subsequent calls). Can only be called by the current owner.
   * @param calls The advanced calls to execute.
   * @return callResults The results of each advanced call.
   */
  function executeAdvanced(
    AdvancedCall[] calldata calls
  ) external override onlyOwner() returns (AdvancedCallReturn[] memory callResults) {
    // Ensure that each `to` address is a contract and is not this contract.
    for (uint256 i = 0; i < calls.length; i++) {
      if (calls[i].value == 0) {
        _ensureValidGenericCallTarget(calls[i].to);
      }
    }

    // Note: from this point on, there are no reverts (apart from out-of-gas or
    // call-depth-exceeded) originating from this contract. However, one of the
    // calls may revert, in which case the function will return `false`, along
    // with the revert reason encoded as bytes, and fire an CallFailure event.

    // Specify length of returned values in order to work with them in memory.
    callResults = new AdvancedCallReturn[](calls.length);

    // Set self-call context to call _executeAdvanced.
    _selfCallContext = this.executeAdvanced.selector;

    // Make the atomic self-call - if any call fails, calls that preceded it
    // will be rolled back and calls that follow it will not be made.
    (bool externalOk, bytes memory rawCallResults) = address(this).call(
      abi.encodeWithSelector(
        this._executeAdvanced.selector, calls
      )
    );

    // Note: there are more efficient ways to check for revert reasons.
    if (
      rawCallResults.length > 68 && // prefix (4) + position (32) + length (32)
      rawCallResults[0] == bytes1(0x08) &&
      rawCallResults[1] == bytes1(0xc3) &&
      rawCallResults[2] == bytes1(0x79) &&
      rawCallResults[3] == bytes1(0xa0)
    ) {
      assembly {
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }
    }

    // Ensure that self-call context has been cleared.
    if (!externalOk) {
      delete _selfCallContext;
    }

    // Parse data returned from self-call into each call result and store / log.
    callResults = abi.decode(rawCallResults, (AdvancedCallReturn[]));
    for (uint256 i = 0; i < callResults.length; i++) {
      AdvancedCall memory currentCall = calls[i];

      // Emit CallSuccess or CallFailure event based on the outcome of the call.
      if (callResults[i].ok) {
        // Note: while the call succeeded, the action may still have "failed".
        emit CallSuccess(
          !externalOk, // If another call failed this will have been rolled back
          currentCall.to,
          uint256(callResults[i].callValue),
          callResults[i].callData,
          callResults[i].returnData
        );
      } else {
        // Note: while the call failed, the nonce will still be incremented,
        // which will invalidate all supplied signatures.
        emit CallFailure(
          currentCall.to,
          uint256(callResults[i].callValue),
          callResults[i].callData,
          _decodeRevertReason(callResults[i].returnData)
        );

        // exit early - any calls after the first failed call will not execute.
        break;
      }
    }
  }

  /**
   * @dev "Internal" helper to execute an atomic batch of advanced calls.
   * Can only be called from this contract during a call to `executeAdvanced`.
   * @param calls The advanced calls to execute.
   * @return callResults The results of each advanced call.
   */
  function _executeAdvanced(
    AdvancedCall[] memory calls
  ) public returns (AdvancedCallReturn[] memory callResults) {
    // Ensure caller is this contract and self-call context is correctly set.
    _enforceSelfCallFrom(this.executeAdvanced.selector);

    bool rollBack = false;
    callResults = new AdvancedCallReturn[](calls.length);

    for (uint256 i = 0; i < calls.length; i++) {
      AdvancedCall memory a = calls[i];
      uint256 callValue = uint256(a.value);
      bytes memory callData = a.data;
      uint256 callIndex;

      // Perform low-level call and set return values using result.
      (bool ok, bytes memory returnData) = a.to.call{value: callValue}(callData);
      callResults[i] = AdvancedCallReturn({
          ok: ok,
          returnData: returnData,
          callValue: uint96(callValue),
          callData: callData
      });
      if (!ok) {
        // Exit early - any calls after the first failed call will not execute.
        rollBack = true;
        break;
      }

      for (uint256 j = 0; j < a.replaceValue.length; j++) {
        callIndex = uint256(a.replaceValue[j].callIndex);

        // Note: this check could be performed prior to execution.
        if (i >= callIndex) {
          revert("Cannot replace value using call that has not yet been performed.");
        }

        uint256 returnOffset = uint256(a.replaceValue[j].returnDataOffset);
        uint256 valueLength = uint256(a.replaceValue[j].valueLength);

        // Note: this check could be performed prior to execution.
        if (valueLength == 0 || valueLength > 32) {
          revert("bad valueLength");
        }

        if (returnData.length < returnOffset + valueLength) {
          revert("Return values are too short to give back a value at supplied index.");
        }

        AdvancedCall memory callTarget = calls[callIndex];
        uint256 valueOffset = 32 - valueLength;
        assembly {
          returndatacopy(
            add(add(callTarget, 32), valueOffset), returnOffset, valueLength
          )
        }
      }

      for (uint256 k = 0; k < a.replaceData.length; k++) {
        callIndex = uint256(a.replaceData[k].callIndex);

        // Note: this check could be performed prior to execution.
        if (i >= callIndex) {
          revert("Cannot replace data using call that has not yet been performed.");
        }

        uint256 callOffset = uint256(a.replaceData[k].callDataOffset);
        uint256 returnOffset = uint256(a.replaceData[k].returnDataOffset);
        uint256 dataLength = uint256(a.replaceData[k].dataLength);

        if (returnData.length < returnOffset + dataLength) {
          revert("Return values are too short to give back a value at supplied index.");
        }

        bytes memory callTargetData = calls[callIndex].data;

        // Note: this check could be performed prior to execution.
        if (callTargetData.length < callOffset + dataLength) {
          revert("Calldata too short to insert returndata at supplied offset.");
        }

        assembly {
          returndatacopy(
            add(callTargetData, add(32, callOffset)), returnOffset, dataLength
          )
        }
      }
    }

    if (rollBack) {
      // Wrap in length encoding and revert (provide bytes instead of a string).
      bytes memory callResultsBytes = abi.encode(callResults);
      assembly { revert(add(32, callResultsBytes), mload(callResultsBytes)) }
    }
  }

  /**
   * @notice Simulate an atomic batch of calls. Any state changes will be rolled back.
   * @param calls The calls to simulate.
   * @return ok The simulated status of each call.
   * @return returnData The simulated returndata of each call.
   */
  function simulate(
    Call[] calldata calls
  ) external /* view */ override returns (bool[] memory ok, bytes[] memory returnData) {
    // Ensure that each `to` address is a contract and is not this contract.
    for (uint256 i = 0; i < calls.length; i++) {
      if (calls[i].value == 0) {
        _ensureValidGenericCallTarget(calls[i].to);
      }
    }

    // Specify length of returned values in order to work with them in memory.
    ok = new bool[](calls.length);
    returnData = new bytes[](calls.length);

    // Set self-call context to call _simulateActionWithAtomicBatchCallsAtomic.
    _selfCallContext = this.simulate.selector;

    // Make the atomic self-call - if any call fails, calls that preceded it
    // will be rolled back and calls that follow it will not be made.
    (bool mustBeFalse, bytes memory rawCallResults) = address(this).call(
      abi.encodeWithSelector(
        this._simulate.selector, calls
      )
    );

    // Note: this should never be the case, but check just to be extra safe.
    if (mustBeFalse) {
      revert("Simulation code must revert!");
    }

    // Ensure that self-call context has been cleared.
    delete _selfCallContext;

    // Parse data returned from self-call into each call result and store / log.
    CallReturn[] memory callResults = abi.decode(rawCallResults, (CallReturn[]));
    for (uint256 i = 0; i < callResults.length; i++) {
      // Set the status and the return data / revert reason from the call.
      ok[i] = callResults[i].ok;
      returnData[i] = callResults[i].returnData;

      if (!callResults[i].ok) {
        // exit early - any calls after the first failed call will not execute.
        break;
      }
    }
  }

  /**
   * @dev "Internal" helper to simulate an atomic batch of calls.
   * Can only be called from this contract during a call to `simulate`.
   * @param calls The calls to simulate.
   * @return callResults The simulated results of each call.
   */
  function _simulate(
    Call[] calldata calls
  ) external returns (CallReturn[] memory callResults) {
    // Ensure caller is this contract and self-call context is correctly set.
    _enforceSelfCallFrom(this.simulate.selector);

    callResults = new CallReturn[](calls.length);

    for (uint256 i = 0; i < calls.length; i++) {
      // Perform low-level call and set return values using result.
      (bool ok, bytes memory returnData) = calls[i].to.call{
        value: uint256(calls[i].value)
      }(calls[i].data);
      callResults[i] = CallReturn({ok: ok, returnData: returnData});
      if (!ok) {
        // Exit early - any calls after the first failed call will not execute.
        break;
      }
    }

    // Wrap in length encoding and revert (provide bytes instead of a string).
    bytes memory callResultsBytes = abi.encode(callResults);
    assembly { revert(add(32, callResultsBytes), mload(callResultsBytes)) }
  }

  /**
   * @notice Simulate an atomic batch of advanced calls (where returndata can be used to
   * populate calldata of subsequent calls). Any state changes will be rolled back.
   * @param calls The advanced calls to simulate.
   * @return callResults The simulated results of each advanced call.
   */
  function simulateAdvanced(
    AdvancedCall[] calldata calls
  ) external /* view */ override returns (AdvancedCallReturn[] memory callResults) {
    // Ensure that each `to` address is a contract and is not this contract.
    for (uint256 i = 0; i < calls.length; i++) {
      if (calls[i].value == 0) {
        _ensureValidGenericCallTarget(calls[i].to);
      }
    }

    // Specify length of returned values in order to work with them in memory.
    callResults = new AdvancedCallReturn[](calls.length);

    // Set self-call context to call _simulateActionWithAtomicBatchCallsAtomic.
    _selfCallContext = this.simulateAdvanced.selector;

    // Make the atomic self-call - if any call fails, calls that preceded it
    // will be rolled back and calls that follow it will not be made.
    (bool mustBeFalse, bytes memory rawCallResults) = address(this).call(
      abi.encodeWithSelector(
        this._simulateAdvanced.selector, calls
      )
    );

    // Note: this should never be the case, but check just to be extra safe.
    if (mustBeFalse) {
      revert("Simulation code must revert!");
    }

    // Note: there are more efficient ways to check for revert reasons.
    if (
      rawCallResults.length > 68 && // prefix (4) + position (32) + length (32)
      rawCallResults[0] == bytes1(0x08) &&
      rawCallResults[1] == bytes1(0xc3) &&
      rawCallResults[2] == bytes1(0x79) &&
      rawCallResults[3] == bytes1(0xa0)
    ) {
      assembly {
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }
    }

    // Ensure that self-call context has been cleared.
    delete _selfCallContext;

    // Parse data returned from self-call into each call result and return.
    callResults = abi.decode(rawCallResults, (AdvancedCallReturn[]));
  }

  /**
   * @dev "Internal" helper to simulate an atomic batch of advanced calls.
   * Can only be called from this contract during a call to `simulateAdvanced`.
   * @param calls The advanced calls to simulate.
   * @return callResults The simulated results of each advanced call.
   */
  function _simulateAdvanced(
    AdvancedCall[] calldata calls
  ) external /* view */ returns (AdvancedCallReturn[] memory callResults) {
    // Ensure caller is this contract and self-call context is correctly set.
    _enforceSelfCallFrom(this.simulateAdvanced.selector);

    callResults = new AdvancedCallReturn[](calls.length);

    for (uint256 i = 0; i < calls.length; i++) {
      AdvancedCall memory a = calls[i];
      uint256 callValue = uint256(a.value);
      bytes memory callData = a.data;
      uint256 callIndex;

      // Perform low-level call and set return values using result.
      (bool ok, bytes memory returnData) = a.to.call{value: callValue}(callData);
      callResults[i] = AdvancedCallReturn({
          ok: ok,
          returnData: returnData,
          callValue: uint96(callValue),
          callData: callData
      });
      if (!ok) {
        // Exit early - any calls after the first failed call will not execute.
        break;
      }

      for (uint256 j = 0; j < a.replaceValue.length; j++) {
        callIndex = uint256(a.replaceValue[j].callIndex);

        // Note: this check could be performed prior to execution.
        if (i >= callIndex) {
          revert("Cannot replace value using call that has not yet been performed.");
        }

        uint256 returnOffset = uint256(a.replaceValue[j].returnDataOffset);
        uint256 valueLength = uint256(a.replaceValue[j].valueLength);

        // Note: this check could be performed prior to execution.
        if (valueLength == 0 || valueLength > 32) {
          revert("bad valueLength");
        }

        if (returnData.length < returnOffset + valueLength) {
          revert("Return values are too short to give back a value at supplied index.");
        }

        AdvancedCall memory callTarget = calls[callIndex];
        uint256 valueOffset = 32 - valueLength;
        assembly {
          returndatacopy(
            add(add(callTarget, 32), valueOffset), returnOffset, valueLength
          )
        }
      }

      for (uint256 k = 0; k < a.replaceData.length; k++) {
        callIndex = uint256(a.replaceData[k].callIndex);

        // Note: this check could be performed prior to execution.
        if (i >= callIndex) {
          revert("Cannot replace data using call that has not yet been performed.");
        }

        uint256 callOffset = uint256(a.replaceData[k].callDataOffset);
        uint256 returnOffset = uint256(a.replaceData[k].returnDataOffset);
        uint256 dataLength = uint256(a.replaceData[k].dataLength);

        if (returnData.length < returnOffset + dataLength) {
          revert("Return values are too short to give back a value at supplied index.");
        }

        bytes memory callTargetData = calls[callIndex].data;

        // Note: this check could be performed prior to execution.
        if (callTargetData.length < callOffset + dataLength) {
          revert("Calldata too short to insert returndata at supplied offset.");
        }

        assembly {
          returndatacopy(
            add(callTargetData, add(32, callOffset)), returnOffset, dataLength
          )
        }
      }
    }

    // Wrap in length encoding and revert (provide bytes instead of a string).
    bytes memory callResultsBytes = abi.encode(callResults);
    assembly { revert(add(32, callResultsBytes), mload(callResultsBytes)) }
  }

  /**
   * @notice Enable the MerkleWalletClaimer contract to assign an owner.
   * No other caller is permitted.
   * @param newOwner The owner to assign.
   */
  function claimOwnership(address newOwner) external override {
    require(
      msg.sender == merkleWalletClaimer,
      "Only the MerkleWalletClaimer contract can call this function."
    );

    require(
      _owner == address(0),
      "Cannot claim ownership with an owner already set."
    );

    require(newOwner != address(0), "New owner cannot be the zero address.");

    _setOwner(newOwner);
  }

  /**
   * @notice Allow a new account (`newOwner`) to accept ownership.
   * Can only be called by the current owner.
   * @param newOwner the new potential owner.
   */
  function transferOwnership(address newOwner) external override onlyOwner() {
    require(
      newOwner != address(0),
      "transferOwnership: new potential owner is the zero address."
    );

    _newPotentialOwner = newOwner;
  }

  /**
   * @notice Cancel a transfer of ownership to a new account.
   * Can only be called by the current owner.
   */
  function cancelOwnershipTransfer() external override onlyOwner() {
    delete _newPotentialOwner;
  }

  /**
   * @notice Transfer ownership of the contract to the caller.
   * Can only be called by a new potential owner set by the current owner.
   */
  function acceptOwnership() external override {
    require(
      msg.sender == _newPotentialOwner,
      "acceptOwnership: current owner must set caller as new potential owner."
    );

    delete _newPotentialOwner;

    _setOwner(msg.sender);
  }

  /**
   * @notice Returns the address of the current owner.
   * @return The owner.
   */
  function owner() external view override returns (address) {
    return _owner;
  }

  /**
   * @notice Returns true if the caller is the current owner.
   * @return True if caller is the owner, else false.
   */
  function isOwner() public view override returns (bool) {
    return msg.sender == _owner;
  }

  /**
   * @notice Implementation of EIP-1271.
   * Should return whether the signature provided is valid for the provided data.
   * @param digest Hash of a message signed on the behalf of address(this)
   * @param signature Signature byte array associated with digest
   * @return The EIP-1271 magic value on success, otherwise empty bytes.
   */
  function isValidSignature(
    bytes32 digest,
    bytes memory signature
  ) external view returns (bytes4) {
    return ECDSA.recover(digest, signature) == _owner
      ? this.isValidSignature.selector
      : bytes4(0);
  }

  /**
   * @notice View function for getting the current smart wallet
   * implementation contract address set on the upgrade beacon.
   * @return implementation The current smart wallet implementation contract.
   */
  function getImplementation() external view override returns (address implementation) {
    (bool ok, bytes memory returnData) = _UPGRADE_BEACON.staticcall("");

    if (!(ok && returnData.length == 32)) {
      revert("Could not retrieve implementation.");
    }

    implementation = abi.decode(returnData, (address));
  }

  /**
   * @notice Pure function for getting the current version.
   * @return version The current version.
   */
  function getVersion() external pure override returns (uint256 version) {
    version = _VERSION;
  }

  /**
   * @notice Contract initialization is now a no-op.
   */
  function initialize(address) external pure override {}

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner(), "caller is not the owner.");
    _;
  }

  /**
   * @dev Set the owner of this contract.
   * @param newOwner The new owner to set for this contract.
   */
  function _setOwner(address newOwner) internal {
    emit OwnershipTransferred(_owner, newOwner);

    _owner = newOwner;
  }

  /**
   * @dev Ensure that calls to protected internal helpers originate from the
   * correct source.
   * @param selfCallContext The selector for the originating function.
   */
  function _enforceSelfCallFrom(bytes4 selfCallContext) internal {
    // Ensure caller is this contract and self-call context is correctly set.
    if (msg.sender != address(this) || _selfCallContext != selfCallContext) {
      revert("External accounts or unapproved internal functions cannot call this.");
    }

    // Clear the self-call context.
    delete _selfCallContext;
  }

  /**
   * @dev Ensure that calls specify a valid target.
   * @param to The target account.
   */
  function _ensureValidGenericCallTarget(address to) internal view {
    if (!to.isContract()) {
      revert("Invalid `to` parameter - must supply a contract address containing code.");
    }

    if (to == address(this)) {
      revert("Invalid `to` parameter - cannot supply the address of this contract.");
    }
  }

  /**
   * @dev Decode revert reasons.
   * @param revertData The undecoded returndata from the reverting call.
   */
  function _decodeRevertReason(
    bytes memory revertData
  ) internal pure returns (string memory revertReason) {
    // Solidity prefixes revert reason with 0x08c379a0 -> Error(string) selector
    if (
      revertData.length > 68 && // prefix (4) + position (32) + length (32)
      revertData[0] == bytes1(0x08) &&
      revertData[1] == bytes1(0xc3) &&
      revertData[2] == bytes1(0x79) &&
      revertData[3] == bytes1(0xa0)
    ) {
      // Get the revert reason without the prefix from the revert data.
      bytes memory revertReasonBytes = new bytes(revertData.length - 4);
      for (uint256 i = 4; i < revertData.length; i++) {
        revertReasonBytes[i - 4] = revertData[i];
      }

      // Decode the resultant revert reason as a string.
      revertReason = abi.decode(revertReasonBytes, (string));
    } else {
      // Simply return the default, with no revert reason.
      revertReason = "(no revert reason)";
    }
  }
}