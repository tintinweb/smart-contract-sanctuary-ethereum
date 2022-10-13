// SPDX-License-Identifier: NONE
pragma solidity 0.8.17;

contract MultiSigWallet {
    uint256 public numOwners;
    uint256 public votesRequired;

    enum Status { Unknown, Inactive, Active }
    struct OwnerStatus {
        address a;
        uint256 numApprovals;
        Status status;
    }
    mapping(bytes => bool) private ownerDecisions;
    mapping(address => OwnerStatus) public ownerStatusBook;

    uint256 public transactionIndex = 1;
    enum TransactionStatus { Unknown, Proposed, Executed }
    struct Transaction {
        uint256 txId;
        address to;
        uint256 value;
        bytes data;

        uint256 approvals;
        TransactionStatus status;
    }
    mapping(bytes => bool) private txDecisions;
    mapping(uint256 => Transaction) public transactionStatusBook;

    constructor(){
        ownerStatusBook[msg.sender] = OwnerStatus({
            a: msg.sender,
            numApprovals: 1,
            status: Status.Active
        });
        numOwners = 1;
        votesRequired = 1;
    }

    modifier onlyOwner {
        require(ownerStatusBook[msg.sender].status == Status.Active, "not-owner");
        _;
    }
    modifier knownAddress(address _a) {
        require(ownerStatusBook[_a].status != Status.Unknown, "unknown-address");
        _;
    }
    modifier notSelf(address _voter, address _votee) {
        require(_voter != _votee, "self-acclamation");
        _;
    }

    function proposeNewOwner(address _newAd) public onlyOwner {
        require(ownerStatusBook[_newAd].status == Status.Unknown, "not-new-address");

        ownerStatusBook[_newAd] = OwnerStatus({
            a: _newAd,
            numApprovals: 1,
            status: Status.Inactive
        });

        ownerDecisions[abi.encodePacked(msg.sender, _newAd)] = true;
    }
    function approveOwner(address _a) public onlyOwner knownAddress(_a) notSelf(msg.sender, _a) {
        require(!ownerDecisions[abi.encodePacked(msg.sender, _a)], "already-approved");
        ownerStatusBook[_a].numApprovals += 1;
        ownerDecisions[abi.encodePacked(msg.sender, _a)] = true;
    }
    function disapproveOwner(address _a) public onlyOwner knownAddress(_a) notSelf(msg.sender, _a) {
        require(!!ownerDecisions[abi.encodePacked(msg.sender, _a)], "already-denied");
        ownerStatusBook[_a].numApprovals -= 1;
        ownerDecisions[abi.encodePacked(msg.sender, _a)] = false;
    }

    function adjustVotesRequired() internal {
        if(numOwners % 2 == 0){
            votesRequired = numOwners / 2 + 1;
        }else{
            votesRequired = (numOwners + 1) / 2;
        }
    }
    function activateOwner(address _a) public onlyOwner knownAddress(_a) notSelf(msg.sender, _a) {
        require(ownerStatusBook[_a].numApprovals >= numOwners, "not-enough-support");
        require(ownerStatusBook[_a].status == Status.Inactive, "already-active");

        numOwners += 1;
        ownerStatusBook[_a].status = Status.Active;
        adjustVotesRequired();
    }
    function suspendOwner(address _a) public onlyOwner knownAddress(_a) notSelf(msg.sender, _a) {
        require(ownerStatusBook[_a].numApprovals <= 0, "not-enough-denials");
        require(ownerStatusBook[_a].status == Status.Active, "already-inactive");

        numOwners -= 1;
        ownerStatusBook[_a].status = Status.Inactive;
        adjustVotesRequired();
    }


    modifier txWaiting(uint256 _txId) {
        require(transactionStatusBook[_txId].status != TransactionStatus.Unknown, "unknown-tx");
        require(transactionStatusBook[_txId].status == TransactionStatus.Proposed, "not-waiting");
        _;
    }

    function proposeTransaction(address _to, uint256 _value, bytes calldata _data) public onlyOwner payable {
        require(msg.value >= _value, "insufficient-deposit");
        transactionStatusBook[transactionIndex] = Transaction({
            txId: transactionIndex,
            to: _to,
            value: _value,
            data: _data,
            approvals: 1,
            status: TransactionStatus.Proposed
        });
    }
    function approveTransaction(uint256 _txId) public onlyOwner txWaiting(_txId) {
        require(!txDecisions[abi.encodePacked(msg.sender, _txId)], "already-approved");
        transactionStatusBook[_txId].approvals += 1;
        txDecisions[abi.encodePacked(msg.sender, _txId)] = true;
    }
    function denyTransaction(uint256 _txId) public onlyOwner txWaiting(_txId) {
        require(!!txDecisions[abi.encodePacked(msg.sender, _txId)], "already-denied");
        transactionStatusBook[_txId].approvals -= 1;
        txDecisions[abi.encodePacked(msg.sender, _txId)] = false;
    }
    function executeTransaction(uint256 _txId) public onlyOwner txWaiting(_txId) {
        require(transactionStatusBook[_txId].approvals >= votesRequired, "not-enough-votes");

        Transaction storage transaction = transactionStatusBook[_txId];
        (bool suc, ) = transaction.to.call{ value: transaction.value }(transaction.data);
        require(suc, "tx-failed");
        transactionStatusBook[_txId].status = TransactionStatus.Executed;
    }

    receive() external payable {}
    fallback() external payable {}
}