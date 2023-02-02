// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.18;


interface IERC1271Wallet {

  /**
   * @notice Verifies whether the provided signature is valid with respect to the provided data
   * @dev MUST return the correct magic value if the signature provided is valid for the provided data
   *   > The bytes4 magic value to return when signature is valid is 0x20c13b0b : bytes4(keccak256("isValidSignature(bytes,bytes)")
   *   > This function MAY modify Ethereum's state
   * @param _data       Arbitrary length data signed on the behalf of address(this)
   * @param _signature  Signature byte array associated with _data
   * @return magicValue Magic value 0x20c13b0b if the signature is valid and 0x0 otherwise
   */
  function isValidSignature(
    bytes calldata _data,
    bytes calldata _signature)
    external
    view
    returns (bytes4 magicValue);

  /**
   * @notice Verifies whether the provided signature is valid with respect to the provided hash
   * @dev MUST return the correct magic value if the signature provided is valid for the provided hash
   *   > The bytes4 magic value to return when signature is valid is 0x20c13b0b : bytes4(keccak256("isValidSignature(bytes,bytes)")
   *   > This function MAY modify Ethereum's state
   * @param _hash       keccak256 hash that was signed
   * @param _signature  Signature byte array associated with _data
   * @return magicValue Magic value 0x20c13b0b if the signature is valid and 0x0 otherwise
   */
  function isValidSignature(
    bytes32 _hash,
    bytes calldata _signature)
    external
    view
    returns (bytes4 magicValue);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.18;


interface IERC1155Receiver {
  function onERC1155Received(address, address, uint256, uint256, bytes calldata) external returns (bytes4);
  function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata) external returns (bytes4);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.18;


interface IERC223Receiver {
  function tokenFallback(address, uint256, bytes calldata) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.18;


interface IERC721Receiver {
  function onERC721Received(address, address, uint256, bytes calldata) external returns (bytes4);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.18;

/**
 * @dev Allows modules to access the implementation slot
 */
contract Implementation {
  /**
   * @notice Updates the Wallet implementation
   * @param _imp New implementation address
   * @dev The wallet implementation is stored on the storage slot
   *   defined by the address of the wallet itself
   *   WARNING updating this value may break the wallet and users
   *   must be confident that the new implementation is safe.
   */
  function _setImplementation(address _imp) internal {
    assembly {
      sstore(address(), _imp)
    }
  }

  /**
   * @notice Returns the Wallet implementation
   * @return _imp The address of the current Wallet implementation
   */
  function _getImplementation() internal view returns (address _imp) {
    assembly {
      _imp := sload(address())
    }
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.18;


abstract contract IModuleAuth {
  //                        IMAGE_HASH_KEY = keccak256("org.arcadeum.module.auth.upgradable.image.hash");
  bytes32 internal constant IMAGE_HASH_KEY = bytes32(0xea7157fa25e3aa17d0ae2d5280fa4e24d421c61842aa85e45194e1145aa72bf8);

  event ImageHashUpdated(bytes32 newImageHash);

  // Errors
  error ImageHashIsZero();
  error InvalidSignatureType(bytes1 _type);

  function _signatureValidation(
    bytes32 _digest,
    bytes calldata _signature
  ) internal virtual view returns (
    bool isValid,
    bytes32 subdigest
  );

  function signatureRecovery(
    bytes32 _digest,
    bytes calldata _signature
  ) public virtual view returns (
    uint256 threshold,
    uint256 weight,
    bytes32 imageHash,
    bytes32 subdigest,
    uint256 checkpoint
  );

  /**
   * @notice Validates the signature image
   * @return true if the signature image is valid
   */
  function _isValidImage(bytes32) internal virtual view returns (bool) {
    return false;
  }

  /**
   * @notice Updates the signers configuration of the wallet
   * @param _imageHash New required image hash of the signature
   */
  function updateImageHash(bytes32 _imageHash) external virtual;

  /**
   * @notice Updates the signers configuration of the wallet
   * @param _imageHash New required image hash of the signature
   */
  function _updateImageHash(bytes32 _imageHash) internal virtual;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.18;
pragma experimental ABIEncoderV2;


interface IModuleCalls {
  // Events
  event TxFailed(bytes32 indexed _tx, uint256 _index, bytes _reason);
  event TxExecuted(bytes32 indexed _tx, uint256 _index);

  // Errors
  error NotEnoughGas(uint256 _index, uint256 _requested, uint256 _available);
  error InvalidSignature(bytes32 _hash, bytes _signature);

  // Transaction structure
  struct Transaction {
    bool delegateCall;   // Performs delegatecall
    bool revertOnError;  // Reverts transaction bundle if tx fails
    uint256 gasLimit;    // Maximum gas to be forwarded
    address target;      // Address of the contract to call
    uint256 value;       // Amount of ETH to pass with the call
    bytes data;          // calldata to pass
  }

  /**
   * @notice Allow wallet owner to execute an action
   * @param _txs        Transactions to process
   * @param _nonce      Signature nonce (may contain an encoded space)
   * @param _signature  Encoded signature
   */
  function execute(
    Transaction[] calldata _txs,
    uint256 _nonce,
    bytes calldata _signature
  ) external;

  /**
   * @notice Allow wallet to execute an action
   *   without signing the message
   * @param _txs  Transactions to execute
   */
  function selfExecute(
    Transaction[] calldata _txs
  ) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.18;


interface IModuleCreator {
  /**
   * @notice Creates a contract forwarding eth value
   * @param _code Creation code of the contract
   * @return addr The address of the created contract
   */
  function createContract(bytes calldata _code) external payable returns (address addr);
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.18;


interface IModuleHooks {
  // Errors
  error HookAlreadyExists(bytes4 _signature);
  error HookDoesNotExist(bytes4 _signature);

  /**
   * @notice Reads the implementation hook of a signature
   * @param _signature Signature function
   * @return The address of the implementation hook, address(0) if none
  */
  function readHook(bytes4 _signature) external view returns (address);

  /**
   * @notice Adds a new hook to handle a given function selector
   * @param _signature Signature function linked to the hook
   * @param _implementation Hook implementation contract
   */
  function addHook(bytes4 _signature, address _implementation) external;

  /**
   * @notice Removes a registered hook
   * @param _signature Signature function linked to the hook
   */
  function removeHook(bytes4 _signature) external;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.18;


abstract contract IModuleUpdate {
  // Errors
  error InvalidImplementation(address _implementation);

  /**
   * @notice Updates the implementation of the base wallet
   * @param _implementation New main module implementation
   * @dev WARNING Updating the implementation can brick the wallet
   */
  function updateImplementation(address _implementation) external virtual;

  /**
   * @notice Updates the implementation of the base wallet, used internally.
   * @param _implementation New main module implementation
   * @dev WARNING Updating the implementation can brick the wallet
   */
  function _updateImplementation(address _implementation) internal virtual;
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.18;

import "../../utils/LibBytes.sol";
import "../../utils/SignatureValidator.sol";
import "../../interfaces/IERC1271Wallet.sol";

import "./interfaces/IModuleAuth.sol";

import "./ModuleERC165.sol";

import "./submodules/auth/SequenceBaseSig.sol";
import "./submodules/auth/SequenceDynamicSig.sol";
import "./submodules/auth/SequenceNoChainIdSig.sol";
import "./submodules/auth/SequenceChainedSig.sol";


abstract contract ModuleAuth is
  IModuleAuth,
  ModuleERC165,
  IERC1271Wallet,
  SequenceChainedSig
{
  using LibBytes for bytes;

  bytes1 internal constant LEGACY_TYPE = hex"00";
  bytes1 internal constant DYNAMIC_TYPE = hex"01";
  bytes1 internal constant NO_CHAIN_ID_TYPE = hex"02";
  bytes1 internal constant CHAINED_TYPE = hex"03";

  bytes4 internal constant SELECTOR_ERC1271_BYTES_BYTES = 0x20c13b0b;
  bytes4 internal constant SELECTOR_ERC1271_BYTES32_BYTES = 0x1626ba7e;

  function signatureRecovery(
    bytes32 _digest,
    bytes calldata _signature
  ) public override virtual view returns (
    uint256 threshold,
    uint256 weight,
    bytes32 imageHash,
    bytes32 subdigest,
    uint256 checkpoint
  ) {
    bytes1 signatureType = _signature[0];

    if (signatureType == LEGACY_TYPE) {
      // networkId digest + base recover
      subdigest = SequenceBaseSig.subdigest(_digest);
      (threshold, weight, imageHash, checkpoint) = SequenceBaseSig.recover(subdigest, _signature);
      return (threshold, weight, imageHash, subdigest, checkpoint);
    }

    if (signatureType == DYNAMIC_TYPE) {
      // networkId digest + dynamic recover
      subdigest = SequenceBaseSig.subdigest(_digest);
      (threshold, weight, imageHash, checkpoint) = SequenceDynamicSig.recover(subdigest, _signature);
      return (threshold, weight, imageHash, subdigest, checkpoint);
    }

    if (signatureType == NO_CHAIN_ID_TYPE) {
      // noChainId digest + dynamic recover
      subdigest = SequenceNoChainIdSig.subdigest(_digest);
      (threshold, weight, imageHash, checkpoint) = SequenceDynamicSig.recover(subdigest, _signature);
      return (threshold, weight, imageHash, subdigest, checkpoint);
    }

    if (signatureType == CHAINED_TYPE) {
      // original digest + chained recover
      // (subdigest will be computed in the chained recover)
      return chainedRecover(_digest, _signature);
    }

    revert InvalidSignatureType(signatureType);
  }

  function _signatureValidation(
    bytes32 _digest,
    bytes calldata _signature
  ) internal override virtual view returns (
    bool isValid,
    bytes32 subdigest
  ) {
    uint256 threshold; uint256 weight; bytes32 imageHash;
    (threshold, weight, imageHash, subdigest,) = signatureRecovery(_digest, _signature);
    isValid = weight >= threshold && _isValidImage(imageHash);
  }

  /**
   * @notice Verifies whether the provided signature is valid with respect to the provided data
   * @dev MUST return the correct magic value if the signature provided is valid for the provided data
   *   > The bytes4 magic value to return when signature is valid is 0x20c13b0b : bytes4(keccak256("isValidSignature(bytes,bytes)"))
   * @param _data       Arbitrary length data signed on the behalf of address(this)
   * @param _signatures Signature byte array associated with _data.
   *                    Encoded as abi.encode(Signature[], Configs)
   * @return magicValue Magic value 0x20c13b0b if the signature is valid and 0x0 otherwise
   */
  function isValidSignature(
    bytes calldata _data,
    bytes calldata _signatures
  ) public override virtual view returns (bytes4) {
    // Validate signatures
    (bool isValid,) = _signatureValidation(keccak256(_data), _signatures);
    if (isValid) {
      return SELECTOR_ERC1271_BYTES_BYTES;
    }

    return bytes4(0);
  }

  /**
   * @notice Verifies whether the provided signature is valid with respect to the provided hash
   * @dev MUST return the correct magic value if the signature provided is valid for the provided hash
   *   > The bytes4 magic value to return when signature is valid is 0x1626ba7e : bytes4(keccak256("isValidSignature(bytes32,bytes)"))
   * @param _hash       keccak256 hash that was signed
   * @param _signatures Signature byte array associated with _data.
   *                    Encoded as abi.encode(Signature[], Configs)
   * @return magicValue Magic value 0x1626ba7e if the signature is valid and 0x0 otherwise
   */
  function isValidSignature(
    bytes32 _hash,
    bytes calldata _signatures
  ) public override virtual view returns (bytes4) {
    // Validate signatures
    (bool isValid,) = _signatureValidation(_hash, _signatures);
    if (isValid) {
      return SELECTOR_ERC1271_BYTES32_BYTES;
    }

    return bytes4(0);
  }

  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceID The interface identifier, as specified in ERC-165
   * @return `true` if the contract implements `_interfaceID`
   */
  function supportsInterface(bytes4 _interfaceID) public override virtual pure returns (bool) {
    if (
      _interfaceID == type(IModuleAuth).interfaceId ||
      _interfaceID == type(IERC1271Wallet).interfaceId
    ) {
      return true;
    }

    return super.supportsInterface(_interfaceID);
  }

  /**
   * @notice Updates the signers configuration of the wallet
   * @param _imageHash New required image hash of the signature
   */
  function updateImageHash(bytes32 _imageHash) external override virtual onlySelf {
    _updateImageHash(_imageHash);
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.18;
pragma experimental ABIEncoderV2;

import "./ModuleSelfAuth.sol";
import "./ModuleStorage.sol";
import "./ModuleERC165.sol";
import "./ModuleNonce.sol";
import "./ModuleOnlyDelegatecall.sol";

import "./interfaces/IModuleCalls.sol";
import "./interfaces/IModuleAuth.sol";

import "./submodules/nonce/SubModuleNonce.sol";
import "./submodules/auth/SequenceBaseSig.sol";

import "../../utils/LibOptim.sol";


abstract contract ModuleCalls is IModuleCalls, IModuleAuth, ModuleERC165, ModuleOnlyDelegatecall, ModuleSelfAuth, ModuleNonce {
  /**
   * @notice Allow wallet owner to execute an action
   * @dev Relayers must ensure that the gasLimit specified for each transaction
   *      is acceptable to them. A user could specify large enough that it could
   *      consume all the gas available.
   * @param _txs        Transactions to process
   * @param _nonce      Signature nonce (may contain an encoded space)
   * @param _signature  Encoded signature
   */
  function execute(
    Transaction[] calldata _txs,
    uint256 _nonce,
    bytes calldata _signature
  ) external override virtual onlyDelegatecall {
    // Validate and update nonce
    _validateNonce(_nonce);

    // Hash and verify transaction bundle
    (bool isValid, bytes32 txHash) = _signatureValidation(
      keccak256(
        abi.encode(
          _nonce,
          _txs
        )
      ),
      _signature
    );

    if (!isValid) {
      revert InvalidSignature(txHash, _signature);
    }

    // Execute the transactions
    _execute(txHash, _txs);
  }

  /**
   * @notice Allow wallet to execute an action
   *   without signing the message
   * @param _txs  Transactions to execute
   */
  function selfExecute(
    Transaction[] calldata _txs
  ) external override virtual onlySelf {
    // Hash transaction bundle
    bytes32 txHash = SequenceBaseSig.subdigest(
      keccak256(
        abi.encode('self:', _txs)
      )
    );

    // Execute the transactions
    _execute(txHash, _txs);
  }

  /**
   * @notice Executes a list of transactions
   * @param _txHash  Hash of the batch of transactions
   * @param _txs  Transactions to execute
   */
  function _execute(
    bytes32 _txHash,
    Transaction[] calldata _txs
  ) private {
    unchecked {
      // Execute transaction
      uint256 size = _txs.length;
      for (uint256 i = 0; i < size; i++) {
        Transaction calldata transaction = _txs[i];
        uint256 gasLimit = transaction.gasLimit;

        if (gasleft() < gasLimit) revert NotEnoughGas(i, gasLimit, gasleft());

        bool success;
        if (transaction.delegateCall) {
          success = LibOptim.delegatecall(
            transaction.target,
            gasLimit == 0 ? gasleft() : gasLimit,
            transaction.data
          );
        } else {
          success = LibOptim.call(
            transaction.target,
            transaction.value,
            gasLimit == 0 ? gasleft() : gasLimit,
            transaction.data
          );
        }

        if (success) {
          emit TxExecuted(_txHash, i);
        } else {
          // Avoid copy of return data until neccesary
          _revertBytes(
            transaction.revertOnError,
            _txHash,
            i,
            LibOptim.returnData()
          );
        }
      }
    }
  }

  /**
   * @notice Logs a failed transaction, reverts if the transaction is not optional
   * @param _revertOnError  Signals if it should revert or just log
   * @param _txHash         Hash of the transaction
   * @param _index          Index of the transaction in the batch
   * @param _reason         Encoded revert message
   */
  function _revertBytes(
    bool _revertOnError,
    bytes32 _txHash,
    uint256 _index,
    bytes memory _reason
  ) internal {
    if (_revertOnError) {
      assembly { revert(add(_reason, 0x20), mload(_reason)) }
    } else {
      emit TxFailed(_txHash, _index, _reason);
    }
  }

  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceID The interface identifier, as specified in ERC-165
   * @return `true` if the contract implements `_interfaceID`
   */
  function supportsInterface(bytes4 _interfaceID) public override virtual pure returns (bool) {
    if (_interfaceID == type(IModuleCalls).interfaceId) {
      return true;
    }

    return super.supportsInterface(_interfaceID);
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.18;

import "./interfaces/IModuleCreator.sol";

import "./ModuleSelfAuth.sol";
import "./ModuleERC165.sol";


contract ModuleCreator is IModuleCreator, ModuleERC165, ModuleSelfAuth {
  event CreatedContract(address _contract);

  /**
   * @notice Creates a contract forwarding eth value
   * @param _code Creation code of the contract
   * @return addr The address of the created contract
   */
  function createContract(bytes memory _code) public override virtual payable onlySelf returns (address addr) {
    assembly { addr := create(callvalue(), add(_code, 32), mload(_code)) }
    emit CreatedContract(addr);
  }

  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceID The interface identifier, as specified in ERC-165
   * @return `true` if the contract implements `_interfaceID`
   */
  function supportsInterface(bytes4 _interfaceID) public override virtual pure returns (bool) {
    if (_interfaceID == type(IModuleCreator).interfaceId) {
      return true;
    }

    return super.supportsInterface(_interfaceID);
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.18;
pragma experimental ABIEncoderV2;


abstract contract ModuleERC165 {
  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceID The interface identifier, as specified in ERC-165
   * @dev Adding new hooks will not lead to them being reported by this function
   *      without upgrading the wallet. In addition, developers must ensure that
   *      all inherited contracts by the main module don't conflict and are accounted
   *      to be supported by the supportsInterface method.
   * @return `true` if the contract implements `_interfaceID`
   */
  function supportsInterface(bytes4 _interfaceID) virtual public pure returns (bool) {
    return _interfaceID == this.supportsInterface.selector;
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.18;

import "./interfaces/IModuleHooks.sol";

import "./ModuleSelfAuth.sol";
import "./ModuleStorage.sol";
import "./ModuleERC165.sol";

import "../../interfaces/receivers/IERC1155Receiver.sol";
import "../../interfaces/receivers/IERC721Receiver.sol";
import "../../interfaces/receivers/IERC223Receiver.sol";


contract ModuleHooks is IERC1155Receiver, IERC721Receiver, IModuleHooks, ModuleERC165, ModuleSelfAuth {
  //                       HOOKS_KEY = keccak256("org.arcadeum.module.hooks.hooks");
  bytes32 private constant HOOKS_KEY = bytes32(0xbe27a319efc8734e89e26ba4bc95f5c788584163b959f03fa04e2d7ab4b9a120);

  /**
   * @notice Reads the implementation hook of a signature
   * @param _signature Signature function
   * @return The address of the implementation hook, address(0) if none
  */
  function readHook(bytes4 _signature) external override virtual view returns (address) {
    return _readHook(_signature);
  }

  /**
   * @notice Adds a new hook to handle a given function selector
   * @param _signature Signature function linked to the hook
   * @param _implementation Hook implementation contract
   * @dev Can't overwrite hooks that are part of the main module (those defined below)
   */
  function addHook(bytes4 _signature, address _implementation) external override virtual onlySelf {
    if (_readHook(_signature) != address(0)) revert HookAlreadyExists(_signature);
    _writeHook(_signature, _implementation);
  }

  /**
   * @notice Removes a registered hook
   * @param _signature Signature function linked to the hook
   * @dev Can't remove hooks that are part of the main module (those defined below)
   *      without upgrading the wallet
   */
  function removeHook(bytes4 _signature) external override virtual onlySelf {
    if (_readHook(_signature) == address(0)) revert HookDoesNotExist(_signature);
    _writeHook(_signature, address(0));
  }

  /**
   * @notice Reads the implementation hook of a signature
   * @param _signature Signature function
   * @return The address of the implementation hook, address(0) if none
  */
  function _readHook(bytes4 _signature) private view returns (address) {
    return address(uint160(uint256(ModuleStorage.readBytes32Map(HOOKS_KEY, _signature))));
  }

  /**
   * @notice Writes the implementation hook of a signature
   * @param _signature Signature function
   * @param _implementation Hook implementation contract
  */
  function _writeHook(bytes4 _signature, address _implementation) private {
    ModuleStorage.writeBytes32Map(HOOKS_KEY, _signature, bytes32(uint256(uint160(_implementation))));
  }

  /**
   * @notice Handle the receipt of a single ERC1155 token type.
   * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
   */
  function onERC1155Received(
    address,
    address,
    uint256,
    uint256,
    bytes calldata
  ) external override virtual returns (bytes4) {
    return ModuleHooks.onERC1155Received.selector;
  }

  /**
   * @notice Handle the receipt of multiple ERC1155 token types.
   * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
   */
  function onERC1155BatchReceived(
    address,
    address,
    uint256[] calldata,
    uint256[] calldata,
    bytes calldata
  ) external override virtual returns (bytes4) {
    return ModuleHooks.onERC1155BatchReceived.selector;
  }

  /**
   * @notice Handle the receipt of a single ERC721 token.
   * @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
   */
  function onERC721Received(address, address, uint256, bytes calldata) external override virtual returns (bytes4) {
    return ModuleHooks.onERC721Received.selector;
  }

  /**
   * @notice Routes fallback calls through hooks
   */
  fallback() external payable {
    address target = _readHook(msg.sig);
    if (target != address(0)) {
      (bool success, bytes memory result) = target.delegatecall(msg.data);
      assembly {
        if iszero(success)  {
          revert(add(result, 0x20), mload(result))
        }

        return(add(result, 0x20), mload(result))
      }
    }
  }

  /**
   * @notice Allows the wallet to receive ETH
   */
  receive() external payable { }

  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceID The interface identifier, as specified in ERC-165
   * @return `true` if the contract implements `_interfaceID`
   */
  function supportsInterface(bytes4 _interfaceID) public override virtual pure returns (bool) {
    if (
      _interfaceID == type(IModuleHooks).interfaceId ||
      _interfaceID == type(IERC1155Receiver).interfaceId ||
      _interfaceID == type(IERC721Receiver).interfaceId ||
      _interfaceID == type(IERC223Receiver).interfaceId
    ) {
      return true;
    }

    return super.supportsInterface(_interfaceID);
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.18;
pragma experimental ABIEncoderV2;

import "./ModuleStorage.sol";

import "./submodules/nonce/SubModuleNonce.sol";


contract ModuleNonce {
  // Events
  event NonceChange(uint256 _space, uint256 _newNonce);

  // Errors
  error BadNonce(uint256 _space, uint256 _provided, uint256 _current);

  //                       NONCE_KEY = keccak256("org.arcadeum.module.calls.nonce");
  bytes32 private constant NONCE_KEY = bytes32(0x8d0bf1fd623d628c741362c1289948e57b3e2905218c676d3e69abee36d6ae2e);

  /**
   * @notice Returns the next nonce of the default nonce space
   * @dev The default nonce space is 0x00
   * @return The next nonce
   */
  function nonce() external virtual view returns (uint256) {
    return readNonce(0);
  }

  /**
   * @notice Returns the next nonce of the given nonce space
   * @param _space Nonce space, each space keeps an independent nonce count
   * @return The next nonce
   */
  function readNonce(uint256 _space) public virtual view returns (uint256) {
    return uint256(ModuleStorage.readBytes32Map(NONCE_KEY, bytes32(_space)));
  }

  /**
   * @notice Changes the next nonce of the given nonce space
   * @param _space Nonce space, each space keeps an independent nonce count
   * @param _nonce Nonce to write on the space
   */
  function _writeNonce(uint256 _space, uint256 _nonce) internal {
    ModuleStorage.writeBytes32Map(NONCE_KEY, bytes32(_space), bytes32(_nonce));
  }

  /**
   * @notice Verify if a nonce is valid
   * @param _rawNonce Nonce to validate (may contain an encoded space)
   */
  function _validateNonce(uint256 _rawNonce) internal virtual {
    // Retrieve current nonce for this wallet
    (uint256 space, uint256 providedNonce) = SubModuleNonce.decodeNonce(_rawNonce);

    uint256 currentNonce = readNonce(space);
    if (currentNonce != providedNonce) {
      revert BadNonce(space, providedNonce, currentNonce);
    }

    unchecked {
      uint256 newNonce = providedNonce + 1;

      _writeNonce(space, newNonce);
      emit NonceChange(space, newNonce);
      return;
    }
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.18;
pragma experimental ABIEncoderV2;


contract ModuleOnlyDelegatecall {
  address private immutable self;

  error OnlyDelegatecall();

  constructor() {
    self = address(this);
  }

  modifier onlyDelegatecall() {
    if (address(this) == self) {
      revert OnlyDelegatecall();
    }
    _;
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.18;


contract ModuleSelfAuth {
  error OnlySelfAuth(address _sender, address _self);

  modifier onlySelf() {
    if (msg.sender != address(this)) {
      revert OnlySelfAuth(msg.sender, address(this));
    }
    _;
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.18;


library ModuleStorage {
  function writeBytes32(bytes32 _key, bytes32 _val) internal {
    assembly { sstore(_key, _val) }
  }

  function readBytes32(bytes32 _key) internal view returns (bytes32 val) {
    assembly { val := sload(_key) }
  }

  function writeBytes32Map(bytes32 _key, bytes32 _subKey, bytes32 _val) internal {
    bytes32 key = keccak256(abi.encode(_key, _subKey));
    assembly { sstore(key, _val) }
  }

  function readBytes32Map(bytes32 _key, bytes32 _subKey) internal view returns (bytes32 val) {
    bytes32 key = keccak256(abi.encode(_key, _subKey));
    assembly { val := sload(key) }
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.18;

import "./interfaces/IModuleUpdate.sol";

import "./Implementation.sol";
import "./ModuleSelfAuth.sol";
import "./ModuleERC165.sol";

import "../../utils/LibAddress.sol";


contract ModuleUpdate is IModuleUpdate, ModuleERC165, ModuleSelfAuth, Implementation {
  using LibAddress for address;

  event ImplementationUpdated(address newImplementation);

  /**
   * @notice Updates the implementation of the base wallet
   * @param _implementation New main module implementation
   * @dev WARNING Updating the implementation can brick the wallet
   */
  function updateImplementation(address _implementation) external override virtual onlySelf {
    _updateImplementation(_implementation);
  }

  /**
   * @notice Updates the implementation of the base wallet, used internally.
   * @param _implementation New main module implementation
   * @dev WARNING Updating the implementation can brick the wallet
   */
  function _updateImplementation(address _implementation) internal override virtual {
    if (!_implementation.isContract()) revert InvalidImplementation(_implementation);
    _setImplementation(_implementation);
    emit ImplementationUpdated(_implementation);
  }

  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceID The interface identifier, as specified in ERC-165
   * @return `true` if the contract implements `_interfaceID`
   */
  function supportsInterface(bytes4 _interfaceID) public override virtual pure returns (bool) {
    if (_interfaceID == type(IModuleUpdate).interfaceId) {
      return true;
    }

    return super.supportsInterface(_interfaceID);
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.18;

import "../../../../utils/SignatureValidator.sol";
import "../../../../utils/LibBytesPointer.sol";
import "../../../../utils/LibBytes.sol";
import "../../../../utils/LibOptim.sol";


library SequenceBaseSig {
  using LibBytesPointer for bytes;

  uint256 private constant FLAG_SIGNATURE = 0;
  uint256 private constant FLAG_ADDRESS = 1;
  uint256 private constant FLAG_DYNAMIC_SIGNATURE = 2;
  uint256 private constant FLAG_NODE = 3;
  uint256 private constant FLAG_BRANCH = 4;
  uint256 private constant FLAG_SUBDIGEST = 5;
  uint256 private constant FLAG_NESTED = 6;

  error InvalidNestedSignature(bytes32 _hash, address _addr, bytes _signature);
  error InvalidSignatureFlag(uint256 _flag);

  function subdigest(
    bytes32 _digest
  ) internal view returns (bytes32) {
    return keccak256(
      abi.encodePacked(
        "\x19\x01",
        block.chainid,
        address(this),
        _digest
      )
    );
  }

  function _leafForAddressAndWeight(
    address _addr,
    uint96 _weight
  ) internal pure returns (bytes32) {
    unchecked {
      return bytes32(uint256(_weight) << 160 | uint256(uint160(_addr)));
    }
  }

  function _leafForHardcodedSubdigest(
    bytes32 _subdigest
  ) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked('Sequence static digest:\n', _subdigest));
  }

  function _leafForNested(
    bytes32 _node,
    uint256 _threshold,
    uint256 _weight
  ) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked('Sequence nested config:\n', _node, _threshold, _weight));
  }

  function recoverBranch(
    bytes32 _subdigest,
    bytes calldata _signature
  ) internal view returns (
    uint256 weight,
    bytes32 root
  ) {
    unchecked {
      uint256 rindex;

      // Iterate until the image is completed
      while (rindex < _signature.length) {
        // Read next item type
        uint256 flag;
        (flag, rindex) = _signature.readUint8(rindex);

        if (flag == FLAG_ADDRESS) {
          // Read plain address
          uint8 addrWeight; address addr;
          (addrWeight, addr, rindex) = _signature.readUint8Address(rindex);

          // Write weight and address to image
          bytes32 node = _leafForAddressAndWeight(addr, addrWeight);
          root = root != bytes32(0) ? LibOptim.fkeccak256(root, node) : node;
          continue;
        }

        if (flag == FLAG_SIGNATURE) {
          // Read weight
          uint8 addrWeight;
          (addrWeight, rindex) = _signature.readUint8(rindex);

          // Read single signature and recover signer
          uint256 nrindex = rindex + 66;
          address addr = SignatureValidator.recoverSigner(_subdigest, _signature[rindex:nrindex]);
          rindex = nrindex;

          // Acumulate total weight of the signature
          weight += addrWeight;

          // Write weight and address to image
          bytes32 node = _leafForAddressAndWeight(addr, addrWeight);
          root = root != bytes32(0) ? LibOptim.fkeccak256(root, node) : node;
          continue;
        }

        if (flag == FLAG_DYNAMIC_SIGNATURE) {
          // Read signer and weight
          uint8 addrWeight; address addr;
          (addrWeight, addr, rindex) = _signature.readUint8Address(rindex);

          // Read signature size
          uint256 size;
          (size, rindex) = _signature.readUint24(rindex);

          // Read dynamic size signature
          uint256 nrindex = rindex + size;
          if (!SignatureValidator.isValidSignature(_subdigest, addr, _signature[rindex:nrindex])) {
            revert InvalidNestedSignature(_subdigest, addr, _signature[rindex:nrindex]);
          }
          rindex = nrindex;

          // Acumulate total weight of the signature
          weight += addrWeight;

          // Write weight and address to image
          bytes32 node = _leafForAddressAndWeight(addr, addrWeight);
          root = root != bytes32(0) ? LibOptim.fkeccak256(root, node) : node;
          continue;
        }

        if (flag == FLAG_NODE) {
          // Read node hash
          bytes32 node;
          (node, rindex) = _signature.readBytes32(rindex);
          root = root != bytes32(0) ? LibOptim.fkeccak256(root, node) : node;
          continue;
        }

        if (flag == FLAG_BRANCH) {
          // Enter a branch of the signature merkle tree
          uint256 size;
          (size, rindex) = _signature.readUint24(rindex);
          uint256 nrindex = rindex + size;

          uint256 nweight; bytes32 node;
          (nweight, node) = recoverBranch(_subdigest, _signature[rindex:nrindex]);

          weight += nweight;
          root = LibOptim.fkeccak256(root, node);

          rindex = nrindex;
          continue;
        }

        if (flag == FLAG_NESTED) {
          // Enter a branch of the signature merkle tree
          // but with an internal threshold and an external fixed weight
          uint256 externalWeight;
          (externalWeight, rindex) = _signature.readUint8(rindex);

          uint256 internalThreshold;
          (internalThreshold, rindex) = _signature.readUint16(rindex);

          uint256 size;
          (size, rindex) = _signature.readUint24(rindex);
          uint256 nrindex = rindex + size;

          uint256 internalWeight; bytes32 internalRoot;
          (internalWeight, internalRoot) = recoverBranch(_subdigest, _signature[rindex:nrindex]);
          rindex = nrindex;

          if (internalWeight >= internalThreshold) {
            weight += externalWeight;
          }

          bytes32 node = _leafForNested(internalRoot, internalThreshold, externalWeight);
          root = root != bytes32(0) ? LibOptim.fkeccak256(root, node) : node;

          continue;
        }

        if (flag == FLAG_SUBDIGEST) {
          // A hardcoded always accepted digest
          // it pushes the weight to the maximum
          bytes32 hardcoded;
          (hardcoded, rindex) = _signature.readBytes32(rindex);
          if (hardcoded == _subdigest) {
            weight = type(uint256).max;
          }

          bytes32 node = _leafForHardcodedSubdigest(hardcoded);
          root = root != bytes32(0) ? LibOptim.fkeccak256(root, node) : node;
          continue;
        }

        revert InvalidSignatureFlag(flag);
      }
    }
  }

  function recover(
    bytes32 _subdigest,
    bytes calldata _signature
  ) internal view returns (
    uint256 threshold,
    uint256 weight,
    bytes32 imageHash,
    uint256 checkpoint
  ) {
    unchecked {
      (weight, imageHash) = recoverBranch(_subdigest, _signature[6:]);

      // Threshold & checkpoint are the top nodes
      // (but they are first on the signature)
      threshold = LibBytes.readFirstUint16(_signature);
      checkpoint = LibBytes.readUint32(_signature, 2);

      imageHash = LibOptim.fkeccak256(imageHash, bytes32(threshold));
      imageHash = LibOptim.fkeccak256(imageHash, bytes32(checkpoint));
    }
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.18;

import "./SequenceBaseSig.sol";
import "./SequenceNoChainIdSig.sol";

import "../../interfaces/IModuleAuth.sol";

import "../../ModuleSelfAuth.sol";
import "../../ModuleStorage.sol";

import "../../../../utils/LibBytesPointer.sol";
import "../../../../utils/LibOptim.sol";


abstract contract SequenceChainedSig is IModuleAuth, ModuleSelfAuth {
  using LibBytesPointer for bytes;

  bytes32 public constant SET_IMAGE_HASH_TYPE_HASH = keccak256("SetImageHash(bytes32 imageHash)");

  error LowWeightChainedSignature(bytes _signature, uint256 threshold, uint256 _weight);
  error WrongChainedCheckpointOrder(uint256 _current, uint256 _prev);

  function _hashSetImageHashStruct(bytes32 _imageHash) internal pure returns (bytes32) {
    return LibOptim.fkeccak256(SET_IMAGE_HASH_TYPE_HASH, _imageHash);
  }

  function chainedRecover(
    bytes32 _digest,
    bytes calldata _signature
  ) internal view returns (
    uint256 threshold,
    uint256 weight,
    bytes32 imageHash,
    bytes32 subdigest,
    uint256 checkpoint
  ) {
    uint256 rindex = 1;
    uint256 sigSize;

    //
    // First signature out of the loop
    //

    // First uint24 is the size of the signature
    (sigSize, rindex) = _signature.readUint24(rindex);
    uint256 nrindex = sigSize + rindex;

    (
      threshold,
      weight,
      imageHash,
      subdigest,
      checkpoint
    ) = signatureRecovery(
      _digest,
      _signature[rindex:nrindex]
    );

    if (weight < threshold) {
      revert LowWeightChainedSignature(_signature[rindex:nrindex], threshold, weight);
    }

    rindex = nrindex;

    //
    // Following signatures are handled by this loop
    // this is done this way because the last signature does not have a
    // checkpoint to be validated.
    //
    while (rindex < _signature.length) {
      // First uint24 is the size of the signature
      (sigSize, rindex) = _signature.readUint24(rindex);
      nrindex = sigSize + rindex;

      uint256 nextCheckpoint;

      (
        threshold,
        weight,
        imageHash,,
        // Don't change the subdigest
        // it should remain the one of the first signature
        nextCheckpoint
      ) = signatureRecovery(
        _hashSetImageHashStruct(imageHash),
        _signature[rindex:nrindex]
      );

      // Validate signature
      if (weight < threshold) {
        revert LowWeightChainedSignature(_signature[rindex:nrindex], threshold, weight);
      }

      if (nextCheckpoint >= checkpoint) {
        revert WrongChainedCheckpointOrder(nextCheckpoint, checkpoint);
      }

      checkpoint = nextCheckpoint;
      rindex = nrindex;
    }
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.18;

import "./SequenceBaseSig.sol";


library SequenceDynamicSig {
  function recover(
    bytes32 _subdigest,
    bytes calldata _signature
  ) internal view returns (
    uint256 threshold,
    uint256 weight,
    bytes32 imageHash,
    uint256 checkpoint
  ) {
    return SequenceBaseSig.recover(_subdigest, _signature[1:]);
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.18;


library SequenceNoChainIdSig {
  function subdigest(bytes32 _digest) internal view returns (bytes32) {
    return keccak256(
      abi.encodePacked(
        "\x19\x01",
        uint256(0),
        address(this),
        _digest
      )
    );
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.18;


library SubModuleNonce {
  // Nonce schema
  //
  // - space[160]:nonce[96]
  //
  uint256 internal constant NONCE_BITS = 96;
  bytes32 internal constant NONCE_MASK = bytes32(uint256(type(uint96).max));

  /**
   * @notice Decodes a raw nonce
   * @dev Schema: space[160]:type[96]
   * @param _rawNonce Nonce to be decoded
   * @return _space The nonce space of the raw nonce
   * @return _nonce The nonce of the raw nonce
   */
  function decodeNonce(uint256 _rawNonce) internal pure returns (
    uint256 _space,
    uint256 _nonce
  ) {
    unchecked {
      // Decode nonce
      _space = _rawNonce >> NONCE_BITS;
      _nonce = uint256(bytes32(_rawNonce) & NONCE_MASK);
    }
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.18;
pragma experimental ABIEncoderV2;

import "../utils/SignatureValidator.sol";
import "../utils/LibOptim.sol";

import "./commons/submodules/auth/SequenceBaseSig.sol";

import "./commons/Implementation.sol";
import "./commons/ModuleAuth.sol";
import "./commons/ModuleHooks.sol";
import "./commons/ModuleCalls.sol";
import "./commons/ModuleUpdate.sol";
import "./commons/ModuleCreator.sol";

import "../interfaces/receivers/IERC1155Receiver.sol";
import "../interfaces/receivers/IERC721Receiver.sol";

import "../interfaces/IERC1271Wallet.sol";


/**
 * GuestModule implements a Sequence wallet without signatures, nonce or replay protection.
 * executing transactions using this wallet is not an authenticated process, and can be done by any address.
 *
 * @notice This contract is completely public with no security, designed to execute pre-signed transactions
 *   and use Sequence tools without using the wallets.
 */
contract GuestModule is
  ModuleAuth,
  ModuleCalls,
  ModuleCreator
{
  error DelegateCallNotAllowed(uint256 _index);
  error NotSupported();

  /**
   * @notice Allow any caller to execute an action
   * @param _txs Transactions to process
   */
  function execute(
    Transaction[] calldata _txs,
    uint256,
    bytes calldata
  ) public override {
    // Hash transaction bundle
    bytes32 txHash = SequenceBaseSig.subdigest(keccak256(abi.encode('guest:', _txs)));

    // Execute the transactions
    _executeGuest(txHash, _txs);
  }

  /**
   * @notice Allow any caller to execute an action
   * @param _txs Transactions to process
   */
  function selfExecute(
    Transaction[] calldata _txs
  ) public override {
    // Hash transaction bundle
    bytes32 txHash = SequenceBaseSig.subdigest(keccak256(abi.encode('self:', _txs)));

    // Execute the transactions
    _executeGuest(txHash, _txs);
  }

  /**
   * @notice Executes a list of transactions
   * @param _txHash  Hash of the batch of transactions
   * @param _txs  Transactions to execute
   */
  function _executeGuest(
    bytes32 _txHash,
    Transaction[] calldata _txs
  ) private {
    // Execute transaction
    uint256 size = _txs.length;
    for (uint256 i = 0; i < size; i++) {
      Transaction calldata transaction = _txs[i];

      if (transaction.delegateCall) revert DelegateCallNotAllowed(i);

      uint256 gasLimit = transaction.gasLimit;
      if (gasleft() < gasLimit) revert NotEnoughGas(i, gasLimit, gasleft());

      bool success = LibOptim.call(
        transaction.target,
        transaction.value,
        gasLimit == 0 ? gasleft() : gasLimit,
        transaction.data
      );

      if (success) {
        emit TxExecuted(_txHash, i);
      } else {
        _revertBytes(
          transaction.revertOnError,
          _txHash,
          i,
          LibOptim.returnData()
        );
      }
    }
  }

  /**
   * @notice Validates any signature image, because the wallet is public and has no owner.
   * @return true, all signatures are valid.
   */
  function _isValidImage(bytes32) internal override pure returns (bool) {
    return true;
  }

  /**
   * Not supported.
   */
  function _updateImageHash(bytes32) internal override virtual {
    revert NotSupported();
  }

  /**
   * @notice Query if a contract implements an interface
   * @param _interfaceID The interface identifier, as specified in ERC-165
   * @return `true` if the contract implements `_interfaceID`
   */
  function supportsInterface(
    bytes4 _interfaceID
  ) public override (
    ModuleAuth,
    ModuleCalls,
    ModuleCreator
  ) pure returns (bool) {
    return super.supportsInterface(_interfaceID);
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.18;


library LibAddress {
  /**
   * @notice Will return true if provided address is a contract
   * @param account Address to verify if contract or not
   * @dev This contract will return false if called within the constructor of
   *      a contract's deployment, as the code is not yet stored on-chain.
   */
  function isContract(address account) internal view returns (bool) {
    uint256 csize;
    // solhint-disable-next-line no-inline-assembly
    assembly { csize := extcodesize(account) }
    return csize != 0;
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.18;


library LibBytes {
  function readBytes32(
    bytes calldata data,
    uint256 index
  ) internal pure returns (
    bytes32 a
  ) {
    assembly {
      a := calldataload(add(data.offset, index))
    }
  }

  function readUint8(
    bytes calldata data,
    uint256 index
  ) internal pure returns (
    uint8 a
  ) {
    assembly {
      let word := calldataload(add(index, data.offset))
      a := shr(248, word)
    }
  }

  function readFirstUint16(
    bytes calldata data
  ) internal pure returns (
    uint16 a
  ) {
    assembly {
      let word := calldataload(data.offset)
      a := shr(240, word)
    }
  }

  function readUint32(
    bytes calldata data,
    uint256 index
  ) internal pure returns (
    uint32 a
  ) {
    assembly {
      let word := calldataload(add(index, data.offset))
      a := shr(224, word)
    }
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.18;


library LibBytesPointer {
  function readFirstUint16(
    bytes calldata data
  ) internal pure returns (
    uint16 a,
    uint256 newPointer
  ) {
    assembly {
      let word := calldataload(data.offset)
      a := shr(240, word)
      newPointer := 2
    }
  }

  function readUint8(
    bytes calldata data,
    uint256 index
  ) internal pure returns (
    uint8 a,
    uint256 newPointer
  ) {
    assembly {
      let word := calldataload(add(index, data.offset))
      a := shr(248, word)
      newPointer := add(index, 1)
    }
  }

  function readUint8Address(
    bytes calldata data,
    uint256 index
  ) internal pure returns (
    uint8 a,
    address b,
    uint256 newPointer
  ) {
    assembly {
      let word := calldataload(add(index, data.offset))
      a := shr(248, word)
      b := and(shr(88, word), 0xffffffffffffffffffffffffffffffffffffffff)
      newPointer := add(index, 21)
    }
  }

  function readUint16(
    bytes calldata data,
    uint256 index
  ) internal pure returns (
    uint16 a,
    uint256 newPointer
  ) {
    assembly {
      let word := calldataload(add(index, data.offset))
      a := and(shr(240, word), 0xffff)
      newPointer := add(index, 2)
    }
  }

  function readUint24(
    bytes calldata data,
    uint256 index
  ) internal pure returns (
    uint24 a,
    uint256 newPointer
  ) {
    assembly {
      let word := calldataload(add(index, data.offset))
      a := and(shr(232, word), 0xffffff)
      newPointer := add(index, 3)
    }
  }

  function readUint64(
    bytes calldata data,
    uint256 index
  ) internal pure returns (
    uint64 a,
    uint256 newPointer
  ) {
    assembly {
      let word := calldataload(add(index, data.offset))
      a := and(shr(192, word), 0xffffffffffffffff)
      newPointer := add(index, 8)
    }
  }

  function readBytes32(
    bytes calldata _data,
    uint256 _pointer
  ) internal pure returns (
    bytes32 _a,
    uint256 _newPointer
  ) {
    assembly {
      _a := calldataload(add(_pointer, _data.offset))
      _newPointer := add(_pointer, 32)
    }
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.18;


library LibOptim {
  /**
    @notice Implements `keccak256(abi.encodePacked(bytes32, bytes32))` using only scratch memory space.

    @param _a First 32 bytes of the hash.
    @param _b Second 32 bytes of the hash.

    @return c The keccak256 hash of the two 32-byte inputs.
  */
  function fkeccak256(
    bytes32 _a,
    bytes32 _b
  ) internal pure returns (bytes32 c) {
    assembly {
      mstore(0, _a)
      mstore(32, _b)
      c := keccak256(0, 64)
    }
  }

  function returnData() internal pure returns (bytes memory r) {
    assembly {
      let size := returndatasize()
      r := mload(0x40)
      let start := add(r, 32)
      mstore(0x40, add(start, size))
      mstore(r, size)
      returndatacopy(start, 0, size)
    }
  }

  function call(
    address _to,
    uint256 _val,
    uint256 _gas,
    bytes calldata _data
  ) internal returns (bool r) {
    assembly {
      let tmp := mload(0x40)
      calldatacopy(tmp, _data.offset, _data.length)

      r := call(
        _gas,
        _to,
        _val,
        tmp,
        _data.length,
        0,
        0
      )
    }
  }

  function delegatecall(
    address _to,
    uint256 _gas,
    bytes calldata _data
  ) internal returns (bool r) {
    assembly {
      let tmp := mload(0x40)
      calldatacopy(tmp, _data.offset, _data.length)

      r := delegatecall(
        _gas,
        _to,
        tmp,
        _data.length,
        0,
        0
      )
    }
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.18;

import "../interfaces/IERC1271Wallet.sol";

import "./LibBytes.sol";

/**
 * @dev Contains logic for signature validation.
 * Signatures from wallet contracts assume ERC-1271 support (https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1271.md)
 * Notes: Methods are strongly inspired by contracts in https://github.com/0xProject/0x-monorepo/blob/development/
 */
library SignatureValidator {
  // Errors
  error InvalidSignatureLength(bytes _signature);
  error InvalidSValue(bytes _signature, bytes32 _s);
  error InvalidVValue(bytes _signature, uint256 _v);
  error UnsupportedSignatureType(bytes _signature, uint256 _type, bool _recoverMode);
  error SignerIsAddress0(bytes _signature);

  using LibBytes for bytes;

  /***********************************|
  |             Variables             |
  |__________________________________*/

  // bytes4(keccak256("isValidSignature(bytes,bytes)"))
  bytes4 constant internal ERC1271_MAGICVALUE = 0x20c13b0b;

  // bytes4(keccak256("isValidSignature(bytes32,bytes)"))
  bytes4 constant internal ERC1271_MAGICVALUE_BYTES32 = 0x1626ba7e;

  // Allowed signature types.
  uint256 private constant SIG_TYPE_EIP712 = 1;
  uint256 private constant SIG_TYPE_ETH_SIGN = 2;
  uint256 private constant SIG_TYPE_WALLET_BYTES32 = 3;

  /***********************************|
  |        Signature Functions        |
  |__________________________________*/

 /**
   * @notice Recover the signer of hash, assuming it's an EOA account
   * @dev Only for SignatureType.EIP712 and SignatureType.EthSign signatures
   * @param _hash      Hash that was signed
   *   encoded as (bytes32 r, bytes32 s, uint8 v, ... , SignatureType sigType)
   */
  function recoverSigner(
    bytes32 _hash,
    bytes calldata _signature
  ) internal pure returns (address signer) {
    if (_signature.length != 66) revert InvalidSignatureLength(_signature);
    uint256 signatureType = _signature.readUint8(_signature.length - 1);

    // Variables are not scoped in Solidity.
    uint8 v = _signature.readUint8(64);
    bytes32 r = _signature.readBytes32(0);
    bytes32 s = _signature.readBytes32(32);

    // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
    // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
    // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
    // signatures from current libraries generate a unique signature with an s-value in the lower half order.
    //
    // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
    // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
    // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
    // these malleable signatures as well.
    //
    // Source OpenZeppelin
    // https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/cryptography/ECDSA.sol

    if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
      revert InvalidSValue(_signature, s);
    }

    if (v != 27 && v != 28) {
      revert InvalidVValue(_signature, v);
    }

    // Signature using EIP712
    if (signatureType == SIG_TYPE_EIP712) {
      signer = ecrecover(_hash, v, r, s);

    // Signed using web3.eth_sign() or Ethers wallet.signMessage()
    } else if (signatureType == SIG_TYPE_ETH_SIGN) {
      signer = ecrecover(
        keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)),
        v,
        r,
        s
      );

    } else {
      // We cannot recover the signer for any other signature type.
      revert UnsupportedSignatureType(_signature, signatureType, true);
    }

    // Prevent signer from being 0x0
    if (signer == address(0x0)) revert SignerIsAddress0(_signature);

    return signer;
  }

 /**
   * @notice Returns true if the provided signature is valid for the given signer.
   * @dev Supports SignatureType.EIP712, SignatureType.EthSign, and ERC1271 signatures
   * @param _hash      Hash that was signed
   * @param _signer    Address of the signer candidate
   * @param _signature Signature byte array
   */
  function isValidSignature(
    bytes32 _hash,
    address _signer,
    bytes calldata _signature
  ) internal view returns (bool valid) {
    uint256 signatureType = uint8(_signature[_signature.length - 1]);

    if (signatureType == SIG_TYPE_EIP712 || signatureType == SIG_TYPE_ETH_SIGN) {
      // Recover signer and compare with provided
      valid = recoverSigner(_hash, _signature) == _signer;

    } else if (signatureType == SIG_TYPE_WALLET_BYTES32) {
      // Remove signature type before calling ERC1271, restore after call
      valid = ERC1271_MAGICVALUE_BYTES32 == IERC1271Wallet(_signer).isValidSignature(_hash, _signature[0:_signature.length - 1]);

    } else {
      // We cannot validate any other signature type.
      // We revert because we can say nothing about its validity.
      revert UnsupportedSignatureType(_signature, signatureType, false);
    }
  }
}