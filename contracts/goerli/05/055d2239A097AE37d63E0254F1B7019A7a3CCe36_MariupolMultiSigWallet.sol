// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "./IERC20.sol";

contract MariupolMultiSigWallet {
    address[] private keyHolders;
    mapping(address => bool) isHolder;
    uint256 public required;

    address private KyivTokenAddress;
    address private KyivTokenOwnerAddress;

    IERC20 KyivToken;

    struct Transaction {
        address to;
        uint256 value;
        bool executed;
    }

    Transaction[] public transactions;
    mapping(uint256 => mapping(address => bool)) public approved;

    event Submit(uint256 indexed transactionId);
    event Approve(address indexed keyHolder, uint256 indexed transactionId);
    event Revoke(address    indexed keyHolder, uint256 indexed transactionId);
    event Execute(uint256 indexed transactionId);

    modifier onlyHolder() {
        require(isHolder[msg.sender], "not a keyholder");
        _;
    }

    modifier transactionExist(uint256 _transactionId) {
        require(
            _transactionId < transactions.length,
            "transaction does not exist"
        );
        _;
    }

    modifier notApproved(uint256 _transactionId) {
        require(
            !approved[_transactionId][msg.sender],
            "transaction is already approved!"
        );
        _;
    }

    modifier notExecuted(uint256 _transactionId) {
        require(
            !transactions[_transactionId].executed,
            "transaction is already executed!"
        );
        _;
    }

    constructor(
        address[] memory _keyHolders,
        address _KyivTokenAddress,
        address _KyivTokenOwnerAddress
    ) {
        require(_keyHolders.length > 0, "Not enough keyholders!");

        for (uint8 i; i < _keyHolders.length; i++) {
            address keyHolder = _keyHolders[i];
            require(keyHolder != address(0), "invalid keyholder");
            require(!isHolder[keyHolder], "keyholder is not unique");

            isHolder[keyHolder] = true;
            keyHolders.push(keyHolder);
        }

        required = (keyHolders.length / 2) + 1;

        // keyHolders = _keyHolders;

        KyivTokenAddress = _KyivTokenAddress;
        KyivTokenOwnerAddress = _KyivTokenOwnerAddress;

        KyivToken = IERC20(KyivTokenAddress);
    }

    function submit(address _to, uint256 _value) external onlyHolder {
        
        require(
            KyivToken.balanceOf(address(this)) >= _value,
            "not enough tokens on wallet!"
        );

        transactions.push(
            Transaction({to: _to, value: _value, executed: false})
        );

        emit Submit(transactions.length - 1);
    }

    function approve(uint256 _transactionId)
        external
        onlyHolder
        transactionExist(_transactionId)
        notApproved(_transactionId)
        notExecuted(_transactionId)
    {
        approved[_transactionId][msg.sender] = true;

        emit Approve(msg.sender, _transactionId);
    }

    function _getApprovalCount(uint256 _transactionId)
        private
        view
        returns (uint8 _count)
    {
        for (uint8 i; i < keyHolders.length; i++) {
            if (approved[_transactionId][keyHolders[i]]) {
                _count++;
            }
        }
    }

    function execute(uint256 _transactionId)
        external
        transactionExist(_transactionId)
        notExecuted(_transactionId)
    {   

        uint256 requiredTmp = required;

        if (keyHolders.length==1){

            requiredTmp = 0;

        }
        require(
            _getApprovalCount(_transactionId) > requiredTmp,
            "approvals<=required"
        );


        Transaction memory transaction = transactions[_transactionId];
        
        require(
            KyivToken.balanceOf(address(this)) >= transaction.value,
            "not enough tokens on wallet!"
        );

        KyivToken.transfer(transaction.to, transaction.value);

        emit Execute(_transactionId);
    }

    function revoke(uint256 _transactionId)
        external
        onlyHolder
        transactionExist(_transactionId)
        notExecuted(_transactionId)
    {
        require(
            approved[_transactionId][msg.sender],
            "transaction not approved!"
        );
        approved[_transactionId][msg.sender] = false;
        emit Revoke(msg.sender, _transactionId);
    }
}