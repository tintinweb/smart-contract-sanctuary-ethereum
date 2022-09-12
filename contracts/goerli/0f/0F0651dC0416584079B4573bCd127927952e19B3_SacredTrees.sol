// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./interfaces/IBatchTreeUpdateVerifier.sol";

/// @dev This contract holds a merkle tree of all sacred cash deposit and withdrawal events
contract SacredTrees {
  address public immutable governance;
  address private immutable owner;
  bytes32 public depositRoot;
  bytes32 public previousDepositRoot;
  bytes32 public withdrawalRoot;
  bytes32 public previousWithdrawalRoot;
  address public sacredProxy;
  IBatchTreeUpdateVerifier public treeUpdateVerifier;

  uint256 public constant CHUNK_TREE_HEIGHT = 1;
  uint256 public constant CHUNK_SIZE = 2**CHUNK_TREE_HEIGHT;
  uint256 public constant ITEM_SIZE = 32 + 20 + 4;
  uint256 public constant BYTES_SIZE = 32 + 32 + 4 + CHUNK_SIZE * ITEM_SIZE;
  uint256 public constant SNARK_FIELD = 21888242871839275222246405745257275088548364400416034343698204186575808495617;

  mapping(uint256 => bytes32) public deposits;
  uint256 public depositsLength;
  uint256 public lastProcessedDepositLeaf;
  
  mapping(uint256 => bytes32) public withdrawals;
  uint256 public withdrawalsLength;
  uint256 public lastProcessedWithdrawalLeaf;
  bool private initialized = false;

  event DepositData(address instance, bytes32 indexed hash, uint256 block, uint256 index);
  event WithdrawalData(address instance, bytes32 indexed hash, uint256 block, uint256 index);
  event VerifierUpdated(address newVerifier);
  event ProxyUpdated(address newProxy);

  struct TreeLeaf {
    bytes32 hash;
    address instance;
    uint32 block;
  }

  modifier onlySacredProxy {
    require(msg.sender == sacredProxy, "Not authorized");
    _;
  }
  
  modifier onlyGovernance() {
    require(msg.sender == governance, "Only governance can perform this action");
    _;
  }

  modifier onlyOwner() {
    require(msg.sender == owner, "Not authorized");
    _;
  }

  constructor(
    address _owner,
    address _governance
  ) {
    owner = _owner;
    governance = _governance;
  }

  function initialize(address _sacredProxy, address _treeUpdateVerifier, bytes32 initialRoot) external onlyOwner {
    if(!initialized) {
      sacredProxy = _sacredProxy;
      treeUpdateVerifier = IBatchTreeUpdateVerifier(_treeUpdateVerifier);
      depositRoot = initialRoot;
      withdrawalRoot = initialRoot;
      initialized = true;
    }
  }

  /// @dev Queue a new deposit data to be inserted into a merkle tree
  function registerDeposit(address _instance, bytes32 _commitment) public onlySacredProxy {
    uint256 _depositsLength = depositsLength;
    deposits[_depositsLength] = keccak256(abi.encode(_instance, _commitment, blockNumber()));
    emit DepositData(_instance, _commitment, blockNumber(), _depositsLength);
    depositsLength = _depositsLength + 1;
  }

  /// @dev Queue a new withdrawal data to be inserted into a merkle tree
  function registerWithdrawal(address _instance, bytes32 _nullifierHash) public onlySacredProxy {
    uint256 _withdrawalsLength = withdrawalsLength;
    withdrawals[_withdrawalsLength] = keccak256(abi.encode(_instance, _nullifierHash, blockNumber()));
    emit WithdrawalData(_instance, _nullifierHash, blockNumber(), _withdrawalsLength);
    withdrawalsLength = _withdrawalsLength + 1;
  }

  /// @dev Insert a full batch of queued deposits into a merkle tree
  /// @param _proof A snark proof that elements were inserted correctly
  /// @param _argsHash A hash of snark inputs
  /// @param _argsHash Current merkle tree root
  /// @param _newRoot Updated merkle tree root
  /// @param _pathIndices Merkle path to inserted batch
  /// @param _events A batch of inserted events (leaves)
  function updateDepositTree(
    bytes calldata _proof,
    bytes32 _argsHash,
    bytes32 _currentRoot,
    bytes32 _newRoot,
    uint32 _pathIndices,
    TreeLeaf[CHUNK_SIZE] calldata _events
  ) public {
    uint256 offset = lastProcessedDepositLeaf;
    require(_currentRoot == depositRoot, "Proposed deposit root is invalid");
    require(_pathIndices == offset >> CHUNK_TREE_HEIGHT, "Incorrect deposit insert index");

    bytes memory data = new bytes(BYTES_SIZE);
    assembly {
      mstore(add(data, 0x44), _pathIndices)
      mstore(add(data, 0x40), _newRoot)
      mstore(add(data, 0x20), _currentRoot)
    }
    for (uint256 i = 0; i < CHUNK_SIZE; ++i) {
      (bytes32 hash, address instance, uint32  bn ) = (_events[i].hash, _events[i].instance, _events[i].block);
      bytes32 leafHash = keccak256(abi.encode(instance, hash, bn));
      bytes32 deposit = deposits[offset + i];
      require(leafHash == deposit, "Incorrect deposit");
      assembly {
        let itemOffset := add(data, mul(ITEM_SIZE, i))
        mstore(add(itemOffset, 0x7c), bn)
        mstore(add(itemOffset, 0x78), instance)
        mstore(add(itemOffset, 0x64), hash)
      }
      delete deposits[offset + i];
    }

    uint256 argsHash = uint256(sha256(data)) % SNARK_FIELD;
    require(argsHash == uint256(_argsHash), "Invalid args hash");
    require(treeUpdateVerifier.verifyProof(_proof, [argsHash]), "Invalid deposit tree update proof");

    previousDepositRoot = _currentRoot;
    depositRoot = _newRoot;
    lastProcessedDepositLeaf = offset + CHUNK_SIZE;
  }

  /// @dev Insert a full batch of queued withdrawals into a merkle tree
  /// @param _proof A snark proof that elements were inserted correctly
  /// @param _argsHash A hash of snark inputs
  /// @param _argsHash Current merkle tree root
  /// @param _newRoot Updated merkle tree root
  /// @param _pathIndices Merkle path to inserted batch
  /// @param _events A batch of inserted events (leaves)
  function updateWithdrawalTree(
    bytes calldata _proof,
    bytes32 _argsHash,
    bytes32 _currentRoot,
    bytes32 _newRoot,
    uint32 _pathIndices,
    TreeLeaf[CHUNK_SIZE] calldata _events
  ) public {
    uint256 offset = lastProcessedWithdrawalLeaf;
    require(_currentRoot == withdrawalRoot, "Proposed withdrawal root is invalid");
    require(_pathIndices == offset >> CHUNK_TREE_HEIGHT, "Incorrect withdrawal insert index");

    bytes memory data = new bytes(BYTES_SIZE);
    assembly {
      mstore(add(data, 0x44), _pathIndices)
      mstore(add(data, 0x40), _newRoot)
      mstore(add(data, 0x20), _currentRoot)
    }
    for (uint256 i = 0; i < CHUNK_SIZE; ++i) {
      (bytes32 hash, address instance, uint32 bn) = (_events[i].hash, _events[i].instance, _events[i].block);
      bytes32 leafHash = keccak256(abi.encode(instance, hash, bn));
      bytes32 withdrawal = withdrawals[offset + i];
      require(leafHash == withdrawal, "Incorrect withdrawal");
      assembly {
        let itemOffset := add(data, mul(ITEM_SIZE, i))
        mstore(add(itemOffset, 0x7c), bn)
        mstore(add(itemOffset, 0x78), instance)
        mstore(add(itemOffset, 0x64), hash)
      }
      delete withdrawals[offset + i];
    }

    uint256 argsHash = uint256(sha256(data)) % SNARK_FIELD;
    require(argsHash == uint256(_argsHash), "Invalid args hash");
    require(treeUpdateVerifier.verifyProof(_proof, [argsHash]), "Invalid withdrawal tree update proof");

    previousWithdrawalRoot = _currentRoot;
    withdrawalRoot = _newRoot;
    lastProcessedWithdrawalLeaf = offset + CHUNK_SIZE;
  }

  function validateRoots(bytes32 _depositRoot, bytes32 _withdrawalRoot) public view {
    require(_depositRoot == depositRoot || _depositRoot == previousDepositRoot, "Incorrect deposit tree root");
    require(_withdrawalRoot == withdrawalRoot || _withdrawalRoot == previousWithdrawalRoot, "Incorrect withdrawal tree root");
  }

  function setSacredProxyContract(address _sacredProxy) external onlyGovernance {
    require(_sacredProxy != address(0), "_sacredProxy cannot be zero address");
    sacredProxy = _sacredProxy;
    emit ProxyUpdated(_sacredProxy);
  }

  function setVerifierContract(IBatchTreeUpdateVerifier _treeUpdateVerifier) external onlyGovernance {
    require(address(_treeUpdateVerifier) != address(0), "_treeUpdateVerifier cannot be zero address");
    treeUpdateVerifier = _treeUpdateVerifier;
    emit VerifierUpdated(address(_treeUpdateVerifier));
  }

  function blockNumber() public view virtual returns (uint256) {
    return block.number;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IBatchTreeUpdateVerifier {
  function verifyProof(bytes calldata proof, uint256[1] calldata input) external view returns (bool);
}