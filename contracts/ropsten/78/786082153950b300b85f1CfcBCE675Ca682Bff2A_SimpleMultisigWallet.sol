/**
 *Submitted for verification at Etherscan.io on 2022-05-25
*/

pragma solidity^0.8.14;

// the IERC20 interface lists functions available but no definitions
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient,uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract SimpleMultisigWallet { // POC for MTS Safe

  address[] public owners;
  uint public numConfirmationsRequired;
  mapping(address => bool) public isOwner;

  uint[] public pendingSendTokenTxList; // test 
  
  struct SendTokenTx {
    IERC20 token;
    address to;
    uint amount;
    bool executed;
    uint numConfirmations;
  }

  struct MultiSendFixedTokenFromContractTx {
    IERC20 token;
    address[] to;
    uint amount;
    bool executed;
    uint numConfirmations;
  }

  SendTokenTx[] public sendTokenTxs;
  MultiSendFixedTokenFromContractTx[] public multiSendFixedTokenFromContractTxs;

  modifier onlyOwner() {
    require(isOwner[msg.sender], "not owner");
    _;
  }

  modifier txExists(uint _txIndex) {
    require(_txIndex < sendTokenTxs.length, "tx does not exist");
    _;
  }

  // modifier notConfirmed(uint _txIndex) {
  //   require(!isConfirmed[_txIndex][msg.sender], "tx have already confirmed by you before");
  //   _;
  // }

  modifier notExecuted(uint _txIndex) {
    require(!sendTokenTxs[_txIndex].executed, "tx already executed");
    _;
  }

  // mapping from fn_index => tx_index => owner => bool
  mapping(uint => mapping(uint => mapping(address => bool))) public isConfirmed;

  constructor(address[] memory _owners, uint _numConfirmationsRequired) public {
    require(_owners.length > 0, "owners required");
    require(_numConfirmationsRequired > 0 && _numConfirmationsRequired <= _owners.length, "invalid number of required confirmations");

    for (uint i = 0; i < _owners.length; i++) {
       address owner = _owners[i];
       require(owner != address(0), "invalid owner");
       require(!isOwner[owner], "owner is existed"); 
       isOwner[owner] = true;
       owners.push(owner);
    }
    numConfirmationsRequired = _numConfirmationsRequired;
  }

  // TODO: function index list -> สำหรับใช้ระบุชนิดฟังก์ชั่น

  function deposit() external payable {}

  function balanceOf(IERC20 _token) public view returns (uint) {
    uint balance = _token.balanceOf(address(this));
    return balance;
  }

  function getTxCount(uint _txType) public view returns (uint) {
    if (_txType == 1) { return sendTokenTxs.length; }
    // TODO: another types
    if (_txType == 2) { return multiSendFixedTokenFromContractTxs.length; }
  }

  function getSendTokenTxInfo(uint _sendTokenTxIndex) public view returns (
    IERC20 token,
    address to,
    uint amount,
    bool executed,
    uint numConfirmations
  ) {
    SendTokenTx storage transaction = sendTokenTxs[_sendTokenTxIndex];
    return (
      transaction.token,
      transaction.to,
      transaction.amount,
      transaction.executed,
      transaction.numConfirmations
    );
  }

  function getMultiSendFixedTokenFromContractTxInfo(uint _multiSendFixedTokenFromContractTxIndex) public view returns (
    IERC20 token,
    address[] memory to,
    uint amount,
    bool executed,
    uint numConfirmations
  ) {
    MultiSendFixedTokenFromContractTx storage transaction = multiSendFixedTokenFromContractTxs[_multiSendFixedTokenFromContractTxIndex];
    return (
      transaction.token,
      transaction.to,
      transaction.amount,
      transaction.executed,
      transaction.numConfirmations
    );
  }

  // TODO: if function for submit, confirm, execute
  function submitSendTokenTx(IERC20 _token, address _to, uint _amount) public onlyOwner {
    sendTokenTxs.push(
      SendTokenTx({
        token: _token,
        to: _to,
        amount: _amount,
        executed: false,
        numConfirmations: 0
      })
    );
  } 

  function submitMultiSendFixedTokenFromContractTx(IERC20 _token, address[] memory _to, uint _amount) public onlyOwner {
    multiSendFixedTokenFromContractTxs.push(
      MultiSendFixedTokenFromContractTx({
        token: _token,
        to: _to,
        amount: _amount,
        executed: false,
        numConfirmations: 0
      })
    );
  }

  // TODO: confirm tx (for each functions)
  function confirmSendTokenTx(uint _sendTokenTxIndex) public onlyOwner {
    require(!isConfirmed[1][_sendTokenTxIndex][msg.sender], "tx have already confirmed by you before");
    SendTokenTx storage transaction = sendTokenTxs[_sendTokenTxIndex];
    transaction.numConfirmations += 1;
    isConfirmed[1][_sendTokenTxIndex][msg.sender] = true;

    // TODO: pending tx list when transaction.numConfirmations >= numConfirmationsRequired
    if (transaction.numConfirmations >= numConfirmationsRequired) {
      pendingSendTokenTxList.push(_sendTokenTxIndex);
    }
  }

  function confirmMultiSendFixedTokenFromContractTx(uint _multiSendFixedTokenFromContractTxIndex) public onlyOwner {
    require(!isConfirmed[2][_multiSendFixedTokenFromContractTxIndex][msg.sender], "tx have already confirmed by you before");
    MultiSendFixedTokenFromContractTx storage transaction = multiSendFixedTokenFromContractTxs[_multiSendFixedTokenFromContractTxIndex];
    transaction.numConfirmations += 1;
    isConfirmed[2][_multiSendFixedTokenFromContractTxIndex][msg.sender] = true;
  }

  // execute SendToken
  function exeSendTokenTx(uint _sendTokenTxIndex) internal {
    SendTokenTx storage transaction = sendTokenTxs[_sendTokenTxIndex];
    require(transaction.executed == false);
    require(transaction.numConfirmations >= numConfirmationsRequired, "cannot execute tx bec number of confirmation less than required number");
    require(transaction.token.balanceOf(address(this)) >= transaction.amount, "check the contract token balance");
    transaction.executed = true;
    transaction.token.transfer(transaction.to, transaction.amount);
  }

  function exeMultiSendFixedTokenFromContractTx(uint _multiSendFixedTokenFromContractTxIndex) internal {
    MultiSendFixedTokenFromContractTx storage transaction = multiSendFixedTokenFromContractTxs[_multiSendFixedTokenFromContractTxIndex];
    require(transaction.executed == false);
    require(transaction.numConfirmations >= numConfirmationsRequired, "cannot execute tx bec number of confirmation less than required number");
    require(transaction.to.length > 0);
    require(transaction.amount > 0);
    require(transaction.to.length * transaction.amount <= transaction.token.balanceOf(address(this)));
        
    for (uint256 i = 0; i < transaction.to.length; i++) {
        transaction.token.transfer(transaction.to[i], transaction.amount);
    }
  }

  // TODO: Batch execution for the Superowner
  function batchExeSendTokenTx(uint [] memory _selectedTxIndexList) public onlyOwner {
    // TODO: 1) re-use exe function -> internal 2) executed tx list
    require (_selectedTxIndexList.length != 0, "do not provide empty list");
    uint i = 0; 
    uint j = _selectedTxIndexList.length;
    while(i < j) { // กรณี j = 1 คือกรณีส่ง tx index เดียว
      exeSendTokenTx(_selectedTxIndexList[i]);
      i += 1;
    } 
  }

  function batchExeMultiSendFixedTokenFromContractTx(uint [] memory _selectedTxIndexList) public onlyOwner {
    require (_selectedTxIndexList.length != 0, "do not provide empty list");
    uint i = 0; 
    uint j = _selectedTxIndexList.length;
    while(i < j) { 
      exeMultiSendFixedTokenFromContractTx(_selectedTxIndexList[i]);
      i += 1;
    } 
  }

  function multiBatchExeTx(uint [] memory _selectedSendTokenTxIndexList, uint [] memory _selectedMultiSendFixedTokenFromContractTxIndexList) public onlyOwner {
    require (_selectedSendTokenTxIndexList.length != 0 && _selectedMultiSendFixedTokenFromContractTxIndexList.length != 0, "do not provide empty list");
    uint i = 0; 
    uint j = _selectedSendTokenTxIndexList.length;
    while(i < j) { 
      exeSendTokenTx(_selectedSendTokenTxIndexList[i]);
      i += 1;
    } 
    i = 0;
    j = _selectedMultiSendFixedTokenFromContractTxIndexList.length;
    while(i < j) { 
      exeMultiSendFixedTokenFromContractTx(_selectedMultiSendFixedTokenFromContractTxIndexList[i]);
      i += 1;
    } 
  }
  // TODO: another functions
}

// -- test deploy
// ["0x5B38Da6a701c568545dCfcB03FcB875f56beddC4", "0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2"], 2
// -- submit sendToken
// 0xd9145CCE52D386f254917e481eB44e9943F39138, 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db, 1000000000000000000000
// -- submit sendMultiToken
// 0xd9145CCE52D386f254917e481eB44e9943F39138, ["0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db", "0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB", "0x617F2E2fD72FD9D5503197092aC168c91465E7f2"], 1000000000000000000000