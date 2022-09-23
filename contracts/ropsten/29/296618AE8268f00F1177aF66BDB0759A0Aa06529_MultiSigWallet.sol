/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

//SPDX-License-Identifier:MIT

pragma solidity ^0.8.10;

error MutiSig_OwnersRquired();
error MultSig_InvalidNumberOfOwners();
error MultSig_InvalidOwner();
error MultiSig_InvalidTransactionId();
error MultiSig_AlreadyApproved();
error MultiSig_AlreadyExicuted();
error MultiSig_NeedMoreApprovals();
error MultiSig_TransactionFailed();
error MultiSig_NotApproved();

contract MultiSigWallet {
    event Deposit(address indexed sender, uint amount);
    event Submit(uint indexed txId);
    event Approve(address indexed owner, uint indexed txId);
    event Revoke(address indexed owner, uint txId);
    event Exicute(uint indexed txId);

    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool exicuted;
    }

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint public required;

    Transaction[] public transactions;
    mapping(uint => mapping(address => bool)) public approved;

    modifier onlyOwner() {
        _validateOwner();
        _;
    }

    modifier txExist(uint _txId) {
        _validateTxExist(_txId);
        _;
    }

    modifier notApproved(uint _txId) {
        _validateNotApproved(_txId);
        _;
    }

    modifier notExicuted(uint _txId) {
        _validateMultiSig_AlreadyExicuted(_txId);
        _;
    }

    constructor(address[] memory _owners, uint _required) {
        if (_owners.length < 0) revert MutiSig_OwnersRquired();
        if (_required < 0 && _required > _owners.length)
            revert MultSig_InvalidNumberOfOwners();

        for (uint i; i < _owners.length; ) {
            address owner = _owners[i];
            if (owner == address(0) && isOwner[owner])
                revert MultSig_InvalidOwner();
            isOwner[owner] = true;
            unchecked {
                ++i;
            }
        }

        required = _required;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function submit(
        address _to,
        uint _value,
        bytes calldata _data
    ) external onlyOwner {
        transactions.push(
            Transaction({to: _to, value: _value, data: _data, exicuted: false})
        );

        emit Submit(transactions.length - 1);
    }

    function approve(uint _txId)
        external
        onlyOwner
        txExist(_txId)
        notApproved(_txId)
        notExicuted(_txId)
    {
        approved[_txId][msg.sender] = true;
        emit Approve(msg.sender, _txId);
    }

    function exicute(uint _txId) external txExist(_txId) notExicuted(_txId) {
        if (_getApprovalCount(_txId) < required)
            revert MultiSig_NeedMoreApprovals();
        Transaction storage transaction = transactions[_txId];
        transaction.exicuted = true;
        (bool success, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );
        if (!success) revert MultiSig_TransactionFailed();

        emit Exicute(_txId);
    }

    function revoke(uint _txId) external txExist(_txId) notExicuted(_txId) {
        if (!approved[_txId][msg.sender]) revert MultiSig_NotApproved();

        approved[_txId][msg.sender] = false;

        emit Revoke(msg.sender, _txId);
    }

    /// ***************************************
    /// ****** PRIVATE FUNCTIONS **************
    /// ***************************************

    function _getApprovalCount(uint _txId) private view returns (uint count) {
        for (uint i; i < owners.length; ) {
            if (approved[_txId][owners[i]]) {
                unchecked {
                    count++;
                    i++;
                }
            }
        }
    }

    /// ***************************************
    /// ****** HELPERS ************************
    /// ***************************************

    function _validateOwner() internal view {
        if (!isOwner[msg.sender]) revert MultSig_InvalidOwner();
    }

    function _validateTxExist(uint _txId) internal view {
        if (_txId > transactions.length) revert MultiSig_InvalidTransactionId();
    }

    function _validateMultiSig_AlreadyExicuted(uint _txId) internal view {
        if (transactions[_txId].exicuted) revert MultiSig_AlreadyExicuted();
    }

    function _validateNotApproved(uint _txId) internal view {
        if (approved[_txId][msg.sender]) revert MultiSig_AlreadyApproved();
    }
}