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

import "../../utils/LibBytes.sol";
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

  /**
   * @notice Recovers the threshold, weight, imageHash, subdigest, and checkpoint of a signature.
   * @dev The signature must be prefixed with a type byte, which is used to determine the recovery method.
   *
   * @param _digest Digest of the signed data.
   * @param _signature A Sequence signature.
   *
   * @return threshold The required number of signatures needed to consider the signature valid.
   * @return weight The actual number of signatures collected in the signature.
   * @return imageHash The imageHash of the configuration that signed the message.
   * @return subdigest A modified version of the original digest, unique for each wallet/network.
   * @return checkpoint A nonce that is incremented every time a new configuration is set.
   */
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

  /**
   * @dev Validates a signature.
   *
   * @param _digest Digest of the signed data.
   * @param _signature A Sequence signature.
   *
   * @return isValid Indicates whether the signature is valid or not.
   * @return subdigest A modified version of the original digest, unique for each wallet/network.
   */
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


contract ModuleOnlyDelegatecall {
  address private immutable self;

  error OnlyDelegatecall();

  constructor() {
    self = address(this);
  }

  /**
   * @notice Modifier that only allows functions to be called via delegatecall.
   */
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

import "../../../../utils/SignatureValidator.sol";
import "../../../../utils/LibBytesPointer.sol";
import "../../../../utils/LibBytes.sol";
import "../../../../utils/LibOptim.sol";


/**
 * @title SequenceBaseSig Library
 * @author Agustin Aguilar ([email protected])
 * @notice A Solidity implementation for handling signatures in the Sequence protocol.
 */
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

  /**
  * @notice Generates a subdigest for the input digest (unique for this wallet and network).
  * @param _digest The input digest to generate the subdigest from.
  * @return bytes32 The subdigest generated from the input digest.
  */
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

  /**
  * @notice Generates the leaf for an address and weight.
  * @dev The leaf is generated by concatenating the address and weight.
  *
  * @param _addr The address to generate the leaf for.
  * @param _weight The weight to generate the leaf for.
  * @return bytes32 The leaf generated from the address and weight.
  */
  function _leafForAddressAndWeight(
    address _addr,
    uint96 _weight
  ) internal pure returns (bytes32) {
    unchecked {
      return bytes32(uint256(_weight) << 160 | uint256(uint160(_addr)));
    }
  }

  /**
  * @notice Generates the leaf for a hardcoded subdigest.
  * @dev The leaf is generated by hashing 'Sequence static digest:\n' and the subdigest.
  * @param _subdigest The subdigest to generate the leaf for.
  * @return bytes32 The leaf generated from the hardcoded subdigest.
  */
  function _leafForHardcodedSubdigest(
    bytes32 _subdigest
  ) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked('Sequence static digest:\n', _subdigest));
  }

  /**
  * @notice Generates the leaf for a nested tree node.
  * @dev The leaf is generated by hashing 'Sequence nested config:\n', the node, the threshold and the weight.
  *
  * @param _node The root of the node to generate the leaf for.
  * @param _threshold The internal threshold of the tree.
  * @param _weight The external weight of the tree.
  * @return bytes32 The leaf generated from the nested tree.
  */
  function _leafForNested(
    bytes32 _node,
    uint256 _threshold,
    uint256 _weight
  ) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked('Sequence nested config:\n', _node, _threshold, _weight));
  }

  /**
   * @notice Returns the weight and root of a signature branch.
   * @dev If the signature contains a hardcoded subdigest, and it matches the input digest, then the weight is set to 2 ** 256 - 1.
   *
   * @param _subdigest The digest to verify the signature against.
   * @param _signature The signature branch to recover.
   * @return weight The total weight of the recovered signatures.
   * @return root The root hash of the recovered configuration.
   */
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

  /**
   * @notice Returns the threshold, weight, root, and checkpoint of a signature.
   * @dev To verify the signature, the weight must be greater than or equal to the threshold, and the root
   *      must match the expected `imageHash` of the wallet.
   *
   * @param _subdigest The digest to verify the signature against.
   * @param _signature The signature to recover.
   * @return threshold The minimum weight required for the signature to be valid.
   * @return weight The total weight of the recovered signatures.
   * @return imageHash The root hash of the recovered configuration
   * @return checkpoint The checkpoint of the signature.
   */
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

import "../../interfaces/IModuleAuth.sol";

import "../../ModuleSelfAuth.sol";
import "../../ModuleStorage.sol";

import "../../../../utils/LibBytesPointer.sol";
import "../../../../utils/LibOptim.sol";

/**
 * @title Sequence chained auth recovery submodule
 * @author Agustin Aguilar ([email protected])
 * @notice Defines Sequence signatures that work by delegating control to new configurations.
 * @dev The delegations can be chained together, the first signature is the one that is used to validate
 *      the message, the last signature must match the current on-chain configuration of the wallet.
 */
abstract contract SequenceChainedSig is IModuleAuth, ModuleSelfAuth {
  using LibBytesPointer for bytes;

  bytes32 public constant SET_IMAGE_HASH_TYPE_HASH = keccak256("SetImageHash(bytes32 imageHash)");

  error LowWeightChainedSignature(bytes _signature, uint256 threshold, uint256 _weight);
  error WrongChainedCheckpointOrder(uint256 _current, uint256 _prev);

  /**
   * @notice Defined the special token that must be signed to delegate control to a new configuration.
   * @param _imageHash The hash of the new configuration.
   * @return bytes32 The message hash to be signed.
   */
  function _hashSetImageHashStruct(bytes32 _imageHash) internal pure returns (bytes32) {
    return LibOptim.fkeccak256(SET_IMAGE_HASH_TYPE_HASH, _imageHash);
  }

  /**
   * @notice Returns the threshold, weight, root, and checkpoint of a (chained) signature.
   * 
   * @dev This method return the `threshold`, `weight` and `imageHash` of the last signature in the chain.
   *      Intermediate signatures are validated directly in this method. The `subdigest` is the one of the
   *      first signature in the chain (since that's the one that is used to validate the message).
   *
   * @param _digest The digest to recover the signature from.
   * @param _signature The signature to recover.
   * @return threshold The threshold of the (last) signature.
   * @return weight The weight of the (last) signature.
   * @return imageHash The image hash of the (last) signature.
   * @return subdigest The subdigest of the (first) signature in the chain.
   * @return checkpoint The checkpoint of the (last) signature.
   */
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

    // The following signatures are handled by this loop.
    // This is done this way because the first signature does not have a
    // checkpoint to be validated against.
    while (rindex < _signature.length) {
      // First uint24 is the size of the signature
      (sigSize, rindex) = _signature.readUint24(rindex);
      nrindex = sigSize + rindex;

      uint256 nextCheckpoint;

      (
        threshold,
        weight,
        imageHash,,
        // Do not change the subdigest;
        // it should remain that of the first signature.
        nextCheckpoint
      ) = signatureRecovery(
        _hashSetImageHashStruct(imageHash),
        _signature[rindex:nrindex]
      );

      // Validate signature
      if (weight < threshold) {
        revert LowWeightChainedSignature(_signature[rindex:nrindex], threshold, weight);
      }

      // Checkpoints must be provided in descending order
      // since the first signature is the one that is used to validate the message
      // and the last signature is the one that is used to validate the current configuration
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

  /**
   * @notice Recover a "dynamically encoded" Sequence signature.
   * @dev The Signature is stripped of the first byte, which is the encoding flag.
   *
   * @param _subdigest The digest of the signature.
   * @param _signature The Sequence signature.
   * @return threshold The threshold weight required to validate the signature.
   * @return weight The weight of the signature.
   * @return imageHash The hash of the recovered configuration.
   * @return checkpoint The checkpoint of the configuration.
   */
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

  /**
   * @notice Computes a subdigest for a Sequence signature that works on all chains.
   * @dev The subdigest is computed by removing the chain ID from the digest (using 0 instead).
   * @param _digest The digest of the chain of signatures.
   * @return bytes32 The subdigest with no chain ID.
   */
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

import "../utils/LibOptim.sol";

import "./commons/submodules/auth/SequenceBaseSig.sol";

import "./commons/ModuleAuth.sol";
import "./commons/ModuleCalls.sol";
import "./commons/ModuleCreator.sol";


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


/**
 * @title Library for reading data from bytes arrays
 * @author Agustin Aguilar ([email protected])
 * @notice This library contains functions for reading data from bytes arrays.
 *
 * @dev These functions do not check if the input index is within the bounds of the data array.
 *         Reading out of bounds may return dirty values.
 */
library LibBytes {

  /**
   * @notice Returns the bytes32 value at the given index in the input data.
   * @param data The input data.
   * @param index The index of the value to retrieve.
   * @return a The bytes32 value at the given index.
   */
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

  /**
   * @notice Returns the uint8 value at the given index in the input data.
   * @param data The input data.
   * @param index The index of the value to retrieve.
   * @return a The uint8 value at the given index.
   */
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

  /**
   * @notice Returns the first uint16 value in the input data.
   * @param data The input data.
   * @return a The first uint16 value in the input data.
   */
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

  /**
   * @notice Returns the uint32 value at the given index in the input data.
   * @param data The input data.
   * @param index The index of the value to retrieve.
   * @return a The uint32 value at the given index.
   */
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


/**
 * @title Library for reading data from bytes arrays with a pointer
 * @author Agustin Aguilar ([email protected])
 * @notice This library contains functions for reading data from bytes arrays with a pointer.
 *
 * @dev These functions do not check if the input index is within the bounds of the data array.
 *         Reading out of bounds may return dirty values.
 */
library LibBytesPointer {

  /**
   * @dev Returns the first uint16 value in the input data and updates the pointer.
   * @param _data The input data.
   * @return a The first uint16 value.
   * @return newPointer The new pointer.
   */
  function readFirstUint16(
    bytes calldata _data
  ) internal pure returns (
    uint16 a,
    uint256 newPointer
  ) {
    assembly {
      let word := calldataload(_data.offset)
      a := shr(240, word)
      newPointer := 2
    }
  }

  /**
   * @notice Returns the uint8 value at the given index in the input data and updates the pointer.
   * @param _data The input data.
   * @param _index The index of the value to retrieve.
   * @return a The uint8 value at the given index.
   * @return newPointer The new pointer.
   */
  function readUint8(
    bytes calldata _data,
    uint256 _index
  ) internal pure returns (
    uint8 a,
    uint256 newPointer
  ) {
    assembly {
      let word := calldataload(add(_index, _data.offset))
      a := shr(248, word)
      newPointer := add(_index, 1)
    }
  }

  /**
   * @notice Returns the uint8 value and the address at the given index in the input data and updates the pointer.
   * @param _data The input data.
   * @param _index The index of the value to retrieve.
   * @return a The uint8 value at the given index.
   * @return b The following address value.
   * @return newPointer The new pointer.
   */
  function readUint8Address(
    bytes calldata _data,
    uint256 _index
  ) internal pure returns (
    uint8 a,
    address b,
    uint256 newPointer
  ) {
    assembly {
      let word := calldataload(add(_index, _data.offset))
      a := shr(248, word)
      b := and(shr(88, word), 0xffffffffffffffffffffffffffffffffffffffff)
      newPointer := add(_index, 21)
    }
  }

  /**
   * @notice Returns the uint16 value at the given index in the input data and updates the pointer.
   * @param _data The input data.
   * @param _index The index of the value to retrieve.
   * @return a The uint16 value at the given index.
   * @return newPointer The new pointer.
   */
  function readUint16(
    bytes calldata _data,
    uint256 _index
  ) internal pure returns (
    uint16 a,
    uint256 newPointer
  ) {
    assembly {
      let word := calldataload(add(_index, _data.offset))
      a := and(shr(240, word), 0xffff)
      newPointer := add(_index, 2)
    }
  }

  /**
   * @notice Returns the uint24 value at the given index in the input data and updates the pointer.
   * @param _data The input data.
   * @param _index The index of the value to retrieve.
   * @return a The uint24 value at the given index.
   * @return newPointer The new pointer.
   */
  function readUint24(
    bytes calldata _data,
    uint256 _index
  ) internal pure returns (
    uint24 a,
    uint256 newPointer
  ) {
    assembly {
      let word := calldataload(add(_index, _data.offset))
      a := and(shr(232, word), 0xffffff)
      newPointer := add(_index, 3)
    }
  }

  /**
   * @notice Returns the uint64 value at the given index in the input data and updates the pointer.
   * @param _data The input data.
   * @param _index The index of the value to retrieve.
   * @return a The uint64 value at the given index.
   * @return newPointer The new pointer.
   */
  function readUint64(
    bytes calldata _data,
    uint256 _index
  ) internal pure returns (
    uint64 a,
    uint256 newPointer
  ) {
    assembly {
      let word := calldataload(add(_index, _data.offset))
      a := and(shr(192, word), 0xffffffffffffffff)
      newPointer := add(_index, 8)
    }
  }

  /**
   * @notice Returns the bytes32 value at the given index in the input data and updates the pointer.
   * @param _data The input data.
   * @param _pointer The index of the value to retrieve.
   * @return a The bytes32 value at the given index.
   * @return newPointer The new pointer.
   */
  function readBytes32(
    bytes calldata _data,
    uint256 _pointer
  ) internal pure returns (
    bytes32 a,
    uint256 newPointer
  ) {
    assembly {
      a := calldataload(add(_pointer, _data.offset))
      newPointer := add(_pointer, 32)
    }
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.18;

/**
 * @title Library for optimized EVM operations
 * @author Agustin Aguilar ([email protected])
 * @notice This library contains functions for optimizing certain EVM operations.
 */
library LibOptim {

  /**
   * @notice Computes the keccak256 hash of two 32-byte inputs.
   * @dev It uses only scratch memory space.
   * @param _a The first 32 bytes of the hash.
   * @param _b The second 32 bytes of the hash.
   * @return c The keccak256 hash of the two 32-byte inputs.
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

  /**
   * @notice Returns the return data from the last call.
   * @return r The return data from the last call.
   */
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

  /**
   * @notice Calls another contract with the given parameters.
   * @dev This method doesn't increase the memory pointer.
   * @param _to The address of the contract to call.
   * @param _val The value to send to the contract.
   * @param _gas The amount of gas to provide for the call.
   * @param _data The data to send to the contract.
   * @return r The success status of the call.
   */
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

  /**
   * @notice Calls another contract with the given parameters, using delegatecall.
   * @dev This method doesn't increase the memory pointer.
   * @param _to The address of the contract to call.
   * @param _gas The amount of gas to provide for the call.
   * @param _data The data to send to the contract.
   * @return r The success status of the call.
   */
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
  error EmptySignature();
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
    if (_signature.length == 0) {
      revert EmptySignature();
    }

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