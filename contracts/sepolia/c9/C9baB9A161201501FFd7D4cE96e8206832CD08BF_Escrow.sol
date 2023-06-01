//SPDX-License-Identifier:MIT

pragma solidity ^0.8.10;

contract Escrow {
    enum EscrowStatus { Created, Locked, Released, Refunded, Dispute }

    struct EscrowTransaction {
        address buyer;
        address seller;
        uint256 amount;
        EscrowStatus status;
    }

    address public arbitrator;
    uint256 public transactionCounter;
    mapping (uint256 => EscrowTransaction) private escrowTransactions;

    event EscrowCreated(uint256 indexed transactionId, address indexed buyer, address indexed seller, uint256 amount);
    event EscrowLocked(uint256 indexed transactionId);
    event EscrowReleased(uint256 indexed transactionId);
    event EscrowRefunded(uint256 indexed transactionId);
    event EscrowDisputed(uint256 indexed transactionId);
    event EscrowResolved(uint256 indexed transactionId, address indexed resolver, bool releasedFunds);

    modifier onlyArbitrator() {
        require(msg.sender == arbitrator, "Only the arbitrator can perform this action.");
        _;
    }

    modifier inStatus(uint256 transactionId, EscrowStatus status) {
        require(escrowTransactions[transactionId].status == status, "Transaction is not in the required state.");
        _;
    }

    constructor() {
        arbitrator = msg.sender;
        transactionCounter = 0;
    }

    function createEscrow(address buyer, address seller) external payable onlyArbitrator {
        uint256 transactionId = transactionCounter;
        transactionCounter++;

        escrowTransactions[transactionId] = EscrowTransaction({
            buyer: buyer,
            seller: seller,
            amount: msg.value,
            status: EscrowStatus.Created
        });

        emit EscrowCreated(transactionId, buyer, seller, msg.value);
    }

    function lockEscrow(uint256 transactionId) external onlyArbitrator inStatus(transactionId, EscrowStatus.Created) {
        escrowTransactions[transactionId].status = EscrowStatus.Locked;

        emit EscrowLocked(transactionId);
    }

    function releaseEscrow(uint256 transactionId) external onlyArbitrator inStatus(transactionId, EscrowStatus.Locked) {
        escrowTransactions[transactionId].status = EscrowStatus.Released;

        address payable seller = payable(escrowTransactions[transactionId].seller);
        uint256 amount = escrowTransactions[transactionId].amount;

        seller.transfer(amount);

        emit EscrowReleased(transactionId);
    }

    function refundEscrow(uint256 transactionId) external onlyArbitrator inStatus(transactionId, EscrowStatus.Locked) {
        escrowTransactions[transactionId].status = EscrowStatus.Refunded;

        address payable buyer = payable(escrowTransactions[transactionId].buyer);
        uint256 amount = escrowTransactions[transactionId].amount;

        buyer.transfer(amount);

        emit EscrowRefunded(transactionId);
    }

    function initiateDispute(uint256 transactionId) external onlyArbitrator inStatus(transactionId, EscrowStatus.Locked) {
        escrowTransactions[transactionId].status = EscrowStatus.Dispute;

        emit EscrowDisputed(transactionId);
    }

    function resolveDispute(uint256 transactionId, bool releaseFunds) external onlyArbitrator inStatus(transactionId, EscrowStatus.Dispute) {
        escrowTransactions[transactionId].status = EscrowStatus.Released;

        address payable seller = payable(escrowTransactions[transactionId].seller);
        address payable buyer = payable(escrowTransactions[transactionId].buyer);
        uint256 amount = escrowTransactions[transactionId].amount;

        if (releaseFunds) {
            seller.transfer(amount);
        } else {
            buyer.transfer(amount);
        }

        emit EscrowResolved(transactionId, msg.sender, releaseFunds);
    }

    function getEscrowStatus(uint256 transactionId) external view returns (EscrowStatus) {
        return escrowTransactions[transactionId].status;
    }
}