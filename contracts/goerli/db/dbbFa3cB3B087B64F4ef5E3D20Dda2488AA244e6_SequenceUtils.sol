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

import "../commons/interfaces/IModuleCalls.sol";


contract MultiCallUtils {
  // Errors
  error DelegateCallNotAllowed(uint256 _index);
  error CallReverted(uint256 _index, bytes _result);

  function multiCall(
    IModuleCalls.Transaction[] memory _txs
  ) public payable returns (
    bool[] memory _successes,
    bytes[] memory _results
  ) {
    _successes = new bool[](_txs.length);
    _results = new bytes[](_txs.length);

    for (uint256 i = 0; i < _txs.length; i++) {
      IModuleCalls.Transaction memory transaction = _txs[i];

      if (transaction.delegateCall) revert DelegateCallNotAllowed(i);
      if (gasleft() < transaction.gasLimit) revert IModuleCalls.NotEnoughGas(i, transaction.gasLimit, gasleft());

      // solhint-disable
      (_successes[i], _results[i]) = transaction.target.call{
        value: transaction.value,
        gas: transaction.gasLimit == 0 ? gasleft() : transaction.gasLimit
      }(transaction.data);
      // solhint-enable

      if (!_successes[i] && _txs[i].revertOnError) revert CallReverted(i, _results[i]);
    }
  }

  // ///
  // Globals
  // ///

  function callBlockhash(uint256 _i) external view returns (bytes32) {
    return blockhash(_i);
  }

  function callCoinbase() external view returns (address) {
    return block.coinbase;
  }

  function callDifficulty() external view returns (uint256) {
    return block.prevrandao; // old block.difficulty
  }

  function callPrevrandao() external view returns (uint256) {
    return block.prevrandao;
  }

  function callGasLimit() external view returns (uint256) {
    return block.gaslimit;
  }

  function callBlockNumber() external view returns (uint256) {
    return block.number;
  }

  function callTimestamp() external view returns (uint256) {
    return block.timestamp;
  }

  function callGasLeft() external view returns (uint256) {
    return gasleft();
  }

  function callGasPrice() external view returns (uint256) {
    return tx.gasprice;
  }

  function callOrigin() external view returns (address) {
    return tx.origin;
  }

  function callBalanceOf(address _addr) external view returns (uint256) {
    return _addr.balance;
  }

  function callCodeSize(address _addr) external view returns (uint256 size) {
    assembly { size := extcodesize(_addr) }
  }

  function callCode(address _addr) external view returns (bytes memory code) {
    assembly {
      let size := extcodesize(_addr)
      code := mload(0x40)
      mstore(0x40, add(code, and(add(add(size, 0x20), 0x1f), not(0x1f))))
      mstore(code, size)
      extcodecopy(_addr, add(code, 0x20), 0, size)
    }
  }

  function callCodeHash(address _addr) external view returns (bytes32 codeHash) {
    assembly { codeHash := extcodehash(_addr) }
  }

  function callChainId() external view returns (uint256 id) {
    assembly { id := chainid() }
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.18;

import "../commons/ModuleNonce.sol";
import "../commons/submodules/nonce/SubModuleNonce.sol";


contract RequireUtils {
  /**
   * @notice Validates that a given expiration hasn't expired
   * @dev Used as an optional transaction on a Sequence batch, to create expirable transactions.
   *
   * @param _expiration  Expiration to check
   */
  function requireNonExpired(uint256 _expiration) external view {
    require(block.timestamp < _expiration, "RequireUtils#requireNonExpired: EXPIRED");
  }

  /**
   * @notice Validates that a given wallet has reached a given nonce
   * @dev Used as an optional transaction on a Sequence batch, to define transaction execution order
   *
   * @param _wallet Sequence wallet
   * @param _nonce  Required nonce
   */
  function requireMinNonce(address _wallet, uint256 _nonce) external view {
    (uint256 space, uint256 nonce) = SubModuleNonce.decodeNonce(_nonce);
    uint256 currentNonce = ModuleNonce(_wallet).readNonce(space);
    require(currentNonce >= nonce, "RequireUtils#requireMinNonce: NONCE_BELOW_REQUIRED");
  }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.18;

import "./MultiCallUtils.sol";
import "./RequireUtils.sol";


contract SequenceUtils is
  MultiCallUtils,
  RequireUtils
{ }