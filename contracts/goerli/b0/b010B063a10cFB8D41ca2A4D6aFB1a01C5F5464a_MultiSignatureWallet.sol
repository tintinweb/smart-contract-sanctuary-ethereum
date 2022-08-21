// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "AggregatorV3Interface.sol";

contract MultiSignatureWallet {
    // Transaction events
    event Deposit(
        address indexed sender,
        uint256 ethAmount,
        uint256 usdAmount,
        uint256 balance
    );
    event SubmitTransaction(
        address indexed owner,
        uint256 indexed txIndex,
        address indexed to,
        uint256 weiAmount,
        uint256 usdAmount
    );
    event ConfirmTransaction(address indexed owner, uint256 indexed txIndex);
    event RevokeTransactionConfirmation(
        address indexed owner,
        uint256 indexed txIndex
    );
    event ExecuteTransaction(address indexed owner, uint256 indexed txIndex);

    // Owner events
    event SubmitRequest(
        address indexed owner,
        uint256 indexed requestId,
        address indexed newOwner
    );
    event ConfirmRequest(address indexed owner, uint256 indexed requestId);
    event RevokeRequestConfirmation(
        address indexed owner,
        uint256 indexed requestId
    );
    event ExecuteRequest(address indexed owner, uint256 indexed requestId);

    // -------------------------------------------------------------------------------------------------------------------------

    AggregatorV3Interface internal priceFeed;
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public numConfirmationsRequired;

    struct Transaction {
        address to;
        uint256 weiAmount;
        uint256 usdAmount;
        bytes data;
        bool executed;
        uint256 numConfirmations;
    }
    struct AddOwnerRequest {
        address newOwner;
        bool executed;
        uint256 numConfirmations;
    }

    mapping(uint256 => mapping(address => bool)) public isTransactionConfirmed;
    mapping(uint256 => mapping(address => bool)) public isRequestConfirmed;

    AddOwnerRequest[] public requests;
    Transaction[] public transactions;

    // -------------------------------------------------------------------------------------------------------------------------

    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not owner");
        _;
    }

    // Transaction modifiers
    modifier txExists(uint256 txIndex) {
        require(txIndex < transactions.length, "Tx does not exist");
        _;
    }

    modifier transactionNotExecuted(uint256 txIndex) {
        require(!transactions[txIndex].executed, "Tx already executed");
        _;
    }

    modifier transactionNotConfirmed(uint256 _txIndex) {
        require(
            !isTransactionConfirmed[_txIndex][msg.sender],
            "Tx already confirmed"
        );
        _;
    }

    // Request modifiers
    modifier requestExists(uint256 _requestId) {
        require(_requestId < requests.length, "Request does not exist");
        _;
    }

    modifier requestNotExecuted(uint256 _requestId) {
        require(!requests[_requestId].executed, "Request already executed");
        _;
    }

    modifier requestNotConfirmed(uint256 _requestId) {
        require(
            !isRequestConfirmed[_requestId][msg.sender],
            "Request already confirmed"
        );
        _;
    }

    // -------------------------------------------------------------------------------------------------------------------------

    // Constructor
    constructor(address[] memory _owners, uint256 _numConfirmationsRequired) {
        priceFeed = AggregatorV3Interface(
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        );

        require(_owners.length > 0, "Owners required");
        require(
            _numConfirmationsRequired > 0 &&
                _numConfirmationsRequired <= _owners.length,
            "To many confirmations needed"
        );

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "Invalid owner");
            require(!isOwner[owner], "Owner not unique");

            isOwner[owner] = true;
            owners.push(owner);
        }

        numConfirmationsRequired = _numConfirmationsRequired;
    }

    // -------------------------------------------------------------------------------------------------------------------------

    receive() external payable {
        emit Deposit(
            msg.sender,
            msg.value,
            getPrice(msg.value),
            address(this).balance
        );
    }

    function getPrice(uint256 _weiAmount) public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 usdAmount = _weiAmount * uint256(price);
        return usdAmount / 10**26;
    }

    // -------------------------------------------------------------------------------------------------------------------------

    // Transaction functions
    function submitTransaction(
        address _to,
        uint256 _value,
        bytes memory _data
    ) external onlyOwner {
        uint256 txIndex = transactions.length;
        uint256 usdAmount = getPrice(_value);

        transactions.push(
            Transaction({
                to: _to,
                weiAmount: _value,
                usdAmount: usdAmount,
                data: _data,
                executed: false,
                numConfirmations: 0
            })
        );

        emit SubmitTransaction(msg.sender, txIndex, _to, _value, usdAmount);
    }

    function confirmTransaction(uint256 _txIndex)
        external
        onlyOwner
        txExists(_txIndex)
        transactionNotExecuted(_txIndex)
        transactionNotConfirmed(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        isTransactionConfirmed[_txIndex][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    function executeTransaction(uint256 _txIndex)
        external
        onlyOwner
        txExists(_txIndex)
        transactionNotExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(
            transaction.numConfirmations >= numConfirmationsRequired,
            "Unconfirmed transaction yet"
        );

        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.weiAmount}(
            transaction.data
        );
        require(success, "Tx failed");

        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    function revokeTransactionConfirmation(uint256 _txIndex)
        external
        onlyOwner
        txExists(_txIndex)
        transactionNotExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        require(
            isTransactionConfirmed[_txIndex][msg.sender],
            "Tx not confirmed"
        );

        transaction.numConfirmations -= 1;
        isTransactionConfirmed[_txIndex][msg.sender] = false;

        emit RevokeTransactionConfirmation(msg.sender, _txIndex);
    }

    // -------------------------------------------------------------------------------------------------------------------------

    // Request functions
    function submitRequest(address _newOwner) external onlyOwner {
        uint256 requestId = requests.length;

        requests.push(
            AddOwnerRequest({
                newOwner: _newOwner,
                executed: false,
                numConfirmations: 0
            })
        );

        emit SubmitRequest(msg.sender, requestId, _newOwner);
    }

    function confirmRequest(uint256 _requestId)
        external
        onlyOwner
        requestExists(_requestId)
        requestNotExecuted(_requestId)
        requestNotConfirmed(_requestId)
    {
        AddOwnerRequest storage request = requests[_requestId];
        request.numConfirmations += 1;
        isRequestConfirmed[_requestId][msg.sender] = true;

        emit ConfirmRequest(msg.sender, _requestId);
    }

    function executeRequest(uint256 _requestId)
        external
        onlyOwner
        requestExists(_requestId)
        requestNotExecuted(_requestId)
    {
        AddOwnerRequest storage request = requests[_requestId];

        require(
            request.numConfirmations >= numConfirmationsRequired,
            "Unconfirmed request yet"
        );

        request.executed = true;

        owners.push(request.newOwner);
        require(
            owners[owners.length - 1] == request.newOwner,
            "Add owner failed"
        );
        numConfirmationsRequired += 1;

        emit ExecuteRequest(msg.sender, _requestId);
    }

    function revokeRequestConfirmation(uint256 _requestId)
        external
        onlyOwner
        requestExists(_requestId)
        requestNotExecuted(_requestId)
    {
        AddOwnerRequest storage request = requests[_requestId];

        require(isRequestConfirmed[_requestId][msg.sender], "Tx not confirmed");

        request.numConfirmations -= 1;
        isRequestConfirmed[_requestId][msg.sender] = false;

        emit RevokeRequestConfirmation(msg.sender, _requestId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

}