// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./MultiSigWallet.sol";

contract MultiSigFactory {

  event MultiSigCreated(address indexed multiSig);

  function createMultiSig(address[] memory owners, uint256 required) external {
    MultiSigWallet multiSig = new MultiSigWallet(owners, required);

    emit MultiSigCreated(address(multiSig));
  }

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract MultiSigWallet {
  event Deposit(address indexed sender, uint256 amount);
  event Submit(uint256 indexed txId, address to, uint256 value, bytes data);
  event Approve(address indexed owner, uint256 indexed txId);
  event Revoke(address indexed owner, uint256 indexed txId);
  event Execute(uint256 indexed txId);

  struct Transaction {
    address to;
    uint256 value;
    bytes data;
    bool executed;
  }

  address[] public owners;
  mapping(address => bool) public isOwner;
  uint256 public required;

  Transaction[] public transactions;
  mapping(uint256 => mapping(address => bool)) public approved;

  modifier onlyOwner() {
    require(isOwner[msg.sender], "Only owner");
    _;
  }

  modifier txExists(uint256 _txId) {
    require(_txId < transactions.length, "Tx doesn't exist");
    _;
  }

  modifier notApproved(uint256 _txId) {
    require(!approved[_txId][msg.sender], "Tx already approved");
    _;
  }

  modifier notExecuted(uint256 _txId) {
    require(!transactions[_txId].executed, "Tx already executed");
    _;
  }

  constructor(address[] memory _owners, uint256 _required) {
    require(_owners.length > 0, "At least 1 owner required");
    require(_required > 0 && _required <= _owners.length, "Invalid number of required");

    for (uint256 i; i < _owners.length; i++) {
      address owner = _owners[i];
      require(owner != address(0), "Invalid address");
      require(!isOwner[owner], "Owner is not unique");

      isOwner[owner] = true;

      owners.push(owner);
    }

    required = _required;
  }

  receive() external payable {
    emit Deposit(msg.sender, msg.value);
  }

  // Calldata is cheaper than memory when function is external
  function submit(address _to, uint256 _value, bytes calldata _data) 
    external 
    onlyOwner
  {
    transactions.push(Transaction({
      to: _to,
      value: _value,
      data: _data,
      executed: false
    }));
    emit Submit(transactions.length - 1, _to, _value, _data);
  }

  function approve(uint256 _txId) 
    external
    onlyOwner
    txExists(_txId)
    notApproved(_txId)
    notExecuted(_txId)
  {
    approved[_txId][msg.sender] = true;
    emit Approve(msg.sender, _txId);
  }

  function _getApprovalCount(uint256 _txId) private view returns (uint256 count) {
    for (uint256 i; i < owners.length; i++) {
      if (approved[_txId][owners[i]]) {
        count++;
      }
    }
  }

  function execute(uint256 _txId) 
    external
    txExists(_txId)
    notExecuted(_txId)
  {
    require(_getApprovalCount(_txId) >= required, "Required not met");
    Transaction storage transaction = transactions[_txId];

    transaction.executed = true;

    (bool success, ) = transaction.to.call{value: transaction.value}(transaction.data);
    require(success, "Tx failed");

    emit Execute(_txId);
  }

  function revoke(uint256 _txId)
    external
    onlyOwner
    txExists(_txId)
    notExecuted(_txId)
  {
    require(approved[_txId][msg.sender], "Not approved");
    approved[_txId][msg.sender] = false;

    emit Revoke(msg.sender, _txId);

  }
}