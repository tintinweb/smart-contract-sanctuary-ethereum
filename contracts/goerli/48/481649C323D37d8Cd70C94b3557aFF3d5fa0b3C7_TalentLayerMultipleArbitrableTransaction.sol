// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Arbitrator.sol";
import "./IArbitrable.sol";
import "../interfaces/IJobRegistry.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TalentLayerMultipleArbitrableTransaction is IArbitrable {
    // **************************** //
    // *    Contract variables    * //
    // **************************** //

    uint8 constant AMOUNT_OF_CHOICES = 2;
    uint8 constant SENDER_WINS = 1;
    uint8 constant RECEIVER_WINS = 2;

    enum Party {
        Sender,
        Receiver
    }
    enum Status {
        NoDispute,
        WaitingSender,
        WaitingReceiver,
        DisputeCreated,
        Resolved
    }

    struct WalletFee {
        address payable wallet;
        uint fee;
    }

    struct Transaction {
        uint256 jobId; 
        uint256 proposalId; 
        address payable sender;
        address payable receiver;
        uint amount;
        uint timeoutPayment; // Time in seconds after which the transaction can be automatically executed if not disputed.
        uint disputeId; // If dispute exists, the ID of the dispute.
        uint senderFee; // Total fees paid by the sender.
        uint receiverFee; // Total fees paid by the receiver.
        uint lastInteraction; // Last interaction for the dispute procedure.
        Status status;
    }

    struct ExtendedTransaction {
        address token;
        Transaction _transaction;
        WalletFee adminFee;
    }

    ExtendedTransaction[] public transactions;
    bytes public arbitratorExtraData; // Extra data to set up the arbitration.
    Arbitrator public arbitrator; // Address of the arbitrator contract.
    uint public feeTimeout; // Time in seconds a party can take to pay arbitration fees before being considered unresponding and lose the dispute.
    address jobRegistryAddress;

    mapping(uint256 => uint256) public disputeIDtoTransactionID; // One-to-one relationship between the dispute and the transaction.

    // **************************** //
    // *          Events          * //
    // **************************** //

    /** @dev To be emitted when a party pays or reimburses the other.
     *  @param _transactionID The index of the transaction.
     *  @param _amount The amount paid.
     *  @param _party The party that paid.
     */
    event Payment(uint indexed _transactionID, uint _amount, address _party);

    /** @dev Indicate that a party has to pay a fee or would otherwise be considered as losing.
     *  @param _transactionID The index of the transaction.
     *  @param _party The party who has to pay.
     */
    event HasToPayFee(uint indexed _transactionID, Party _party);

    /** @dev To be raised when a ruling is given.
     *  @param _arbitrator The arbitrator giving the ruling.
     *  @param _disputeID ID of the dispute in the Arbitrator contract.
     *  @param _ruling The ruling which was given.
     */
    // event Ruling(Arbitrator indexed _arbitrator, uint indexed _disputeID, uint _ruling);

    /** @dev Emitted when a transaction is created.
     *  @param _transactionID The index of the transaction.
     *  @param _sender The address of the sender.
     *  @param _receiver The address of the receiver.
     *  @param _amount The initial amount in the transaction.
     */
    event TransactionCreated(
        uint _transactionID,
        address indexed _sender,
        address indexed _receiver,
        uint _amount
    );

    // **************************** //
    // *    Arbitrable functions  * //
    // *    Modifying the state   * //
    // **************************** //

    /** @dev Constructor.
     *  @param _arbitrator The arbitrator of the contract.
     *  @param _arbitratorExtraData Extra data for the arbitrator.
     *  @param _feeTimeout Arbitration fee timeout for the parties.
     */
    constructor(
        address _jobRegistryAddress,
        Arbitrator _arbitrator, 
        bytes memory _arbitratorExtraData,
        uint _feeTimeout
    ) {
        setJobRegistryAddress(_jobRegistryAddress);
        arbitrator = _arbitrator;
        arbitratorExtraData = _arbitratorExtraData;
        feeTimeout = _feeTimeout;
    }

    /** @dev Allows changing the contract address to JobRegistry.sol
     *  @param _jobRegistryAddress The new contract address.
     */
    function setJobRegistryAddress(address _jobRegistryAddress) public {
        jobRegistryAddress = _jobRegistryAddress;
    }

    /** @dev Create a ETH-based transaction.
     *  @param _timeoutPayment Time after which a party can automatically execute the arbitrable transaction.
     *  @param _sender The recipient of the transaction.
     *  @param _receiver The recipient of the transaction.
     *  @param _metaEvidence Link to the meta-evidence.
     *  @param _adminWallet Admin fee wallet.
     *  @param _adminFeeAmount Admin fee amount.
     *  @return transactionID The index of the transaction.
     **/
    function createETHTransaction(
        uint _timeoutPayment,
        address payable _sender,
        address payable _receiver,
        string memory _metaEvidence,
        uint256 _amount,
        address payable _adminWallet,
        uint _adminFeeAmount,
        uint256 _jobId,
        uint256 _proposalId
    ) public payable returns (uint transactionID) {
        require(
            _amount + _adminFeeAmount == msg.value,
            "Fees or amounts don't match with payed amount."
        );
        //address(this).transfer(msg.value); Need to look up

        return createTransaction(
            _timeoutPayment,
            _sender,
            _receiver,
            _metaEvidence,
            _amount,
            address(0),
            _adminWallet,
            _adminFeeAmount,
            _jobId,
            _proposalId
        );
    }

   /** @dev Create a token-based transaction.
     *  @param _timeoutPayment Time after which a party can automatically execute the arbitrable transaction.
     *  @param _sender The recipient of the transaction.
     *  @param _receiver The recipient of the transaction.
     *  @param _metaEvidence Link to the meta-evidence.
     *  @param _tokenAddress Address of token used for transaction.
     *  @param _adminWallet Admin fee wallet.
     *  @param _adminFeeAmount Admin fee amount.
     *  @return transactionID The index of the transaction.
     **/
    function createTokenTransaction(
        uint _timeoutPayment,
        address payable _sender,
        address payable _receiver,
        string memory _metaEvidence,
        uint256 _amount,
        address _tokenAddress,
        address payable _adminWallet,
        uint _adminFeeAmount,
        uint256 _jobId,
        uint256 _proposalId
    ) public payable returns (uint transactionID) {
        IERC20 token = IERC20(_tokenAddress);
        // Transfers token from sender wallet to contract. Permit before transfer
        require(
            token.transferFrom(msg.sender, address(this), _amount),
            "Sender does not have enough approved funds."
        );
        require(
            _adminFeeAmount + _adminFeeAmount == msg.value,
            "Fees don't match with payed amount"
        );

        return createTransaction(
            _timeoutPayment,
            _sender,
            _receiver,
            _metaEvidence,
            _amount,
            _tokenAddress,
            _adminWallet,
            _adminFeeAmount,
            _jobId,
            _proposalId
        );
    }

    function createTransaction(
        uint _timeoutPayment,
        address payable _sender,
        address payable _receiver,
        string memory _metaEvidence,
        uint256 _amount,
        address _tokenAddress,
        address payable _adminWallet,
        uint _adminFeeAmount,
        uint256 _jobId, 
        uint256 _proposalId
    ) private returns (uint transactionID) {
        WalletFee memory _adminFee = WalletFee(_adminWallet, _adminFeeAmount);
        Transaction memory _rawTransaction = _initTransaction(_jobId,_proposalId,_sender, _receiver);

        _rawTransaction.amount = _amount;
        _rawTransaction.timeoutPayment = _timeoutPayment;

        ExtendedTransaction memory _transaction = ExtendedTransaction({
            token: _tokenAddress,
            _transaction: _rawTransaction,
            adminFee: _adminFee
        });

        transactions.push(_transaction);
        emit MetaEvidence(transactions.length - 1, _metaEvidence);

        IJobRegistry(jobRegistryAddress).afterDeposit(_jobId, _proposalId, transactions.length - 1);

        return transactions.length - 1;
    }


    /** @dev Pay receiver. To be called if the good or service is provided.
     *  @param _transactionID The index of the transaction.
     *  @param _amount Amount to pay in wei.
     */
    function pay(uint _transactionID, uint _amount) public {
        ExtendedTransaction storage transaction = transactions[_transactionID];
        require(
            transaction._transaction.sender == msg.sender,
            "The caller must be the sender."
        );
        require(
            transaction._transaction.status == Status.NoDispute,
            "The transaction shouldn't be disputed."
        );
        require(
            _amount <= transaction._transaction.amount,
            "The amount paid has to be less than or equal to the transaction."
        );

        _handleTransactionTransfer(
            _transactionID,
            transaction._transaction.receiver,
            _amount,
            transaction._transaction.amount - _amount,
            transaction.token != address(0),
            "pay",
            true
        );

        if(transaction._transaction.amount == 0){
            IJobRegistry(jobRegistryAddress).afterFullPayment(transaction._transaction.jobId);
        }
    }

    /** @dev Reimburse sender. To be called if the good or service can't be fully provided.
     *  @param _transactionID The index of the transaction.
     *  @param _amountReimbursed Amount to reimburse in wei.
     */
    function reimburse(uint _transactionID, uint _amountReimbursed) public {
        ExtendedTransaction storage transaction = transactions[_transactionID];
        require(
            transaction._transaction.receiver == msg.sender,
            "The caller must be the receiver."
        );
        require(
            transaction._transaction.status == Status.NoDispute,
            "The transaction shouldn't be disputed."
        );
        require(
            _amountReimbursed <= transaction._transaction.amount,
            "The amount reimbursed has to be less or equal than the transaction."
        );

        _handleTransactionTransfer(
            _transactionID,
            transaction._transaction.sender,
            _amountReimbursed,
            transaction._transaction.amount - _amountReimbursed,
            transaction.token != address(0),
            "reimburse",
            true
        );
    }

    /** @dev Transfer the transaction's amount to the receiver if the timeout has passed.
     *  @param _transactionID The index of the transaction.
     */
    function executeTransaction(uint _transactionID) public {
        ExtendedTransaction storage transaction = transactions[_transactionID];
        require(
            block.timestamp - transaction._transaction.lastInteraction >= transaction._transaction.timeoutPayment,
            "The timeout has not passed yet."
        );
        require(
            transaction._transaction.status == Status.NoDispute,
            "The transaction shouldn't be disputed."
        );

        _handleTransactionTransfer(
            _transactionID,
            transaction._transaction.receiver,
            transaction._transaction.amount,
            0,
            transaction.token != address(0),
            "pay",
            false
        );
        transaction._transaction.status = Status.Resolved;
    }

    /** @dev Reimburse sender if receiver fails to pay the fee.
     *  @param _transactionID The index of the transaction.
     */
    function timeOutBySender(uint _transactionID) public {
        ExtendedTransaction storage transaction = transactions[_transactionID];
        require(
            transaction._transaction.status == Status.WaitingReceiver,
            "The transaction is not waiting on the receiver."
        );
        require(
            block.timestamp - transaction._transaction.lastInteraction >= feeTimeout,
            "Timeout time has not passed yet."
        );

        /*if (transaction._transaction.receiverFee != 0) {
            transaction._transaction.receiver.transfer(transaction._transaction.receiverFee);
            transaction._transaction.receiverFee = 0;
        }*/
        executeRuling(_transactionID, SENDER_WINS);
    }

    /** @dev Pay receiver if sender fails to pay the fee.
     *  @param _transactionID The index of the transaction.
     */
    function timeOutByReceiver(uint _transactionID) public {
        ExtendedTransaction storage transaction = transactions[_transactionID];
        require(
            transaction._transaction.status == Status.WaitingSender,
            "The transaction is not waiting on the sender."
        );
        require(
            block.timestamp - transaction._transaction.lastInteraction >= feeTimeout,
            "Timeout time has not passed yet."
        );

        /*if (transaction.senderFee != 0) {
            transaction.sender.transfer(transaction.senderFee);
            transaction.senderFee = 0;
        }*/
        executeRuling(_transactionID, RECEIVER_WINS);
    }

    /** @dev Pay the arbitration fee to raise a dispute. To be called by the sender. UNTRUSTED.
     *  Note that the arbitrator can have createDispute throw, which will make this function throw and therefore lead to a party being timed-out.
     *  This is not a vulnerability as the arbitrator can rule in favor of one party anyway.
     *  @param _transactionID The index of the transaction.
     */
    function payArbitrationFeeBySender(uint _transactionID) public payable {
        ExtendedTransaction storage transaction = transactions[_transactionID];
        uint arbitrationCost = arbitrator.arbitrationCost(arbitratorExtraData);

        require(
            transaction._transaction.status < Status.DisputeCreated,
            "Dispute has already been created or because the transaction has been executed."
        );
        require(
            msg.sender == transaction._transaction.sender,
            "The caller must be the sender."
        );

        transaction._transaction.senderFee += msg.value;
        // Require that the total pay at least the arbitration cost.
        require(
            transaction._transaction.senderFee >= arbitrationCost,
            "The sender fee must cover arbitration costs."
        );

        transaction._transaction.lastInteraction = block.timestamp;

        // The receiver still has to pay. This can also happen if he has paid, but arbitrationCost has increased.
        if (transaction._transaction.receiverFee < arbitrationCost) {
            transaction._transaction.status = Status.WaitingReceiver;
            emit HasToPayFee(_transactionID, Party.Receiver);
        } else {
            // The receiver has also paid the fee. We create the dispute.
            raiseDispute(_transactionID, arbitrationCost);
            //performTransactionFee(transaction, "reimburse");
        }
    }

    /** @dev Pay the arbitration fee to raise a dispute. To be called by the receiver. UNTRUSTED.
     *  Note that this function mirrors payArbitrationFeeBySender.
     *  @param _transactionID The index of the transaction.
     */
    function payArbitrationFeeByReceiver(uint _transactionID) public payable {
        ExtendedTransaction storage transaction = transactions[_transactionID];
        uint arbitrationCost = arbitrator.arbitrationCost(arbitratorExtraData);

        require(
            transaction._transaction.status < Status.DisputeCreated,
            "Dispute has already been created or because the transaction has been executed."
        );
        require(
            msg.sender == transaction._transaction.receiver,
            "The caller must be the receiver."
        );

        transaction._transaction.receiverFee += msg.value;
        // Require that the total paid to be at least the arbitration cost.
        require(
            transaction._transaction.receiverFee >= arbitrationCost,
            "The receiver fee must cover arbitration costs."
        );

        transaction._transaction.lastInteraction = block.timestamp;
        // The sender still has to pay. This can also happen if he has paid, but arbitrationCost has increased.
        if (transaction._transaction.senderFee < arbitrationCost) {
            transaction._transaction.status = Status.WaitingSender;
            emit HasToPayFee(_transactionID, Party.Sender);
        } else {
            // The sender has also paid the fee. We create the dispute.
            raiseDispute(_transactionID, arbitrationCost);
        }
    }

    /** @dev Create a dispute. UNTRUSTED.
     *  @param _transactionID The index of the transaction.
     *  @param _arbitrationCost Amount to pay the arbitrator.
     */
    function raiseDispute(uint _transactionID, uint _arbitrationCost) internal {
        ExtendedTransaction storage transaction = transactions[_transactionID];
        transaction._transaction.status = Status.DisputeCreated;
        transaction._transaction.disputeId = arbitrator.createDispute{value: _arbitrationCost}(AMOUNT_OF_CHOICES, arbitratorExtraData);
        disputeIDtoTransactionID[transaction._transaction.disputeId] = _transactionID;
        emit Dispute(
            arbitrator,
            transaction._transaction.disputeId,
            _transactionID,
            _transactionID
        );

        // Refund sender if it overpaid.
        if (transaction._transaction.senderFee > _arbitrationCost) {
            uint extraFeeSender = transaction._transaction.senderFee - _arbitrationCost;
            transaction._transaction.senderFee = _arbitrationCost;
            transaction._transaction.sender.transfer(extraFeeSender);
        }

        // Refund receiver if it overpaid.
        if (transaction._transaction.receiverFee > _arbitrationCost) {
            uint extraFeeReceiver = transaction._transaction.receiverFee - _arbitrationCost;
            transaction._transaction.receiverFee = _arbitrationCost;
            transaction._transaction.receiver.transfer(extraFeeReceiver);
        }
    }

    /** @dev Submit a reference to evidence. EVENT.
     *  @param _transactionID The index of the transaction.
     *  @param _evidence A link to an evidence using its URI.
     */
    function submitEvidence(uint _transactionID, string memory _evidence)
        public
    {
        ExtendedTransaction storage transaction = transactions[_transactionID];
        require(
            msg.sender == transaction._transaction.sender ||
                msg.sender == transaction._transaction.receiver,
            "The caller must be the sender or the receiver."
        );
        require(
            transaction._transaction.status < Status.Resolved,
            "Must not send evidence if the dispute is resolved."
        );

        emit Evidence(arbitrator, _transactionID, msg.sender, _evidence);
    }

    /** @dev Appeal an appealable ruling.
     *  Transfer the funds to the arbitrator.
     *  Note that no checks are required as the checks are done by the arbitrator.
     *  @param _transactionID The index of the transaction.
     */
    function appeal(uint _transactionID) public payable {
        ExtendedTransaction storage transaction = transactions[_transactionID];

        arbitrator.appeal{value: msg.value}(transaction._transaction.disputeId, arbitratorExtraData);
    }

    /** @dev Give a ruling for a dispute. Must be called by the arbitrator.
     *  The purpose of this function is to ensure that the address calling it has the right to rule on the contract.
     *  @param _disputeID ID of the dispute in the Arbitrator contract.
     *  @param _ruling Ruling given by the arbitrator. Note that 0 is reserved for "Not able/wanting to make a decision".
     */
    function rule(uint _disputeID, uint _ruling) public {
        uint transactionID = disputeIDtoTransactionID[_disputeID];
        ExtendedTransaction storage transaction = transactions[transactionID];
        require(
            msg.sender == address(arbitrator),
            "The caller must be the arbitrator."
        );
        require(
            transaction._transaction.status == Status.DisputeCreated,
            "The dispute has already been resolved."
        );

        emit Ruling(Arbitrator(msg.sender), _disputeID, _ruling);

        executeRuling(transactionID, _ruling);
    }

    /** @dev Execute a ruling of a dispute. It reimburses the fee to the winning party.
     *  @param _transactionID The index of the transaction.
     *  @param _ruling Ruling given by the arbitrator. 1 : Reimburse the receiver. 2 : Pay the sender.
     */
    function executeRuling(uint _transactionID, uint _ruling) internal {
        ExtendedTransaction storage transaction = transactions[_transactionID];
        require(_ruling <= AMOUNT_OF_CHOICES, "Invalid ruling.");

        // Give the arbitration fee back.
        // Note that we use send to prevent a party from blocking the execution.
        if (_ruling == SENDER_WINS) {
            transaction._transaction.sender.transfer(transaction._transaction.senderFee + transaction._transaction.amount);
            performTransactionFee(transaction, "reimburse");
        } else if (_ruling == RECEIVER_WINS) {
            transaction._transaction.receiver.transfer(
                transaction._transaction.receiverFee + transaction._transaction.amount
            );
            performTransactionFee(transaction, "pay");
        } else {
            uint split_amount = (transaction._transaction.senderFee + transaction._transaction.amount) /
                2;
            transaction._transaction.sender.transfer(split_amount);
            transaction._transaction.receiver.transfer(split_amount);
            performTransactionFee(transaction, "reimburse");
        }

        transaction._transaction.amount = 0;
        transaction._transaction.senderFee = 0;
        transaction._transaction.receiverFee = 0;
        transaction._transaction.status = Status.Resolved;
    }

    // **************************** //
    // *     Help functions       * //
    // **************************** //

    function _initTransaction(
        uint256 _jobId,
        uint256 _proposalId,
        address payable _sender,
        address payable _receiver
    ) private view returns (Transaction memory) {
        return Transaction({
            jobId: _jobId,
            proposalId: _proposalId,
            sender: _sender,
            receiver: _receiver,
            amount: 0,
            timeoutPayment: 0,
            disputeId: 0,
            senderFee: 0,
            receiverFee: 0,
            lastInteraction: block.timestamp,
            status: Status.NoDispute
        });
    }

    function _handleTransactionTransfer(
        uint _transactionID,
        address payable destination,
        uint amount,
        uint finalAmount,
        bool isToken,
        string memory feeMode,
        bool emitPayment

    ) private {
        ExtendedTransaction storage transaction = transactions[_transactionID];
        if (isToken) {
            require(
                IERC20(transaction.token).transfer(destination, amount),
                "The `transfer` function must not fail."
            );
        } else {
            destination.transfer(amount);
        }
        transaction._transaction.amount = finalAmount;

        // TODO: we should be done only one time 
        // performTransactionFee(transaction, feeMode);

        if (emitPayment) {
            emit Payment(_transactionID, amount, msg.sender);
        }
    }


    function performTransactionFee(ExtendedTransaction memory transaction, string memory mode) private {
        if (compareStrings(mode, "pay")) {
            transaction.adminFee.wallet.transfer(transaction.adminFee.fee);
        } else {
            transaction._transaction.sender.transfer(transaction.adminFee.fee);
        }
    }

    function compareStrings(string memory a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }


    // **************************** //
    // *     Constant getters     * //
    // **************************** //

    /** @dev Getter to know the count of transactions.
     *  @return countTransactions The count of transactions.
     */
    function getCountTransactions() public view returns (uint256 countTransactions){
        return transactions.length;
    }

    /** @dev Get IDs for transactions where the specified address is the receiver and/or the sender.
     *  This function must be used by the UI and not by other smart contracts.
     *  Note that the complexity is O(t), where t is amount of arbitrable transactions.
     *  @param _address The specified address.
     *  @return transactionIDs The transaction IDs.
     */
    function getTransactionIDsByAddress(address _address) public view returns (uint256[] memory transactionIDs) {
        uint256 count = 0;
        for (uint256 i = 0; i < transactions.length; i++) {
            if (
                transactions[i]._transaction.sender == _address ||
                transactions[i]._transaction.receiver == _address
            ) count++;
        }

        transactionIDs = new uint256[](count);

        count = 0;

        for (uint256 j = 0; j < transactions.length; j++) {
            if (
                transactions[j]._transaction.sender == _address ||
                transactions[j]._transaction.receiver == _address
            ) transactionIDs[count++] = j;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Arbitrable.sol";

/** @title Arbitrator
 *  @author Clément Lesaege - <[email protected]>
 *  Arbitrator abstract contract.
 *  When developing arbitrator contracts we need to:
 *  -Define the functions for dispute creation (createDispute) and appeal (appeal). Don't forget to store the arbitrated contract and the disputeID (which should be unique, use nbDisputes).
 *  -Define the functions for cost display (arbitrationCost and appealCost).
 *  -Allow giving rulings. For this a function must call arbitrable.rule(disputeID, ruling).
 */
abstract contract Arbitrator {

    enum DisputeStatus {Waiting, Appealable, Solved}

    modifier requireArbitrationFee(bytes memory _extraData) {
        require(msg.value >= arbitrationCost(_extraData), "Not enough ETH to cover arbitration costs.");
        _;
    }
    modifier requireAppealFee(uint256 _disputeID, bytes memory _extraData) {
        require(msg.value >= appealCost(_disputeID, _extraData), "Not enough ETH to cover appeal costs.");
        _;
    }

    /** @dev To be raised when a dispute is created.
     *  @param _disputeID ID of the dispute.
     *  @param _arbitrable The contract which created the dispute.
     */
    event DisputeCreation(uint256 indexed _disputeID, Arbitrable indexed _arbitrable);

    /** @dev To be raised when a dispute can be appealed.
     *  @param _disputeID ID of the dispute.
     *  @param _arbitrable The contract which created the dispute.
     */
    event AppealPossible(uint256 indexed _disputeID, Arbitrable indexed _arbitrable);

    /** @dev To be raised when the current ruling is appealed.
     *  @param _disputeID ID of the dispute.
     *  @param _arbitrable The contract which created the dispute.
     */
    event AppealDecision(uint256 indexed _disputeID, Arbitrable indexed _arbitrable);

    /** @dev Create a dispute. Must be called by the arbitrable contract.
     *  Must be paid at least arbitrationCost(_extraData).
     *  @param _choices Amount of choices the arbitrator can make in this dispute.
     *  @param _extraData Can be used to give additional info on the dispute to be created.
     *  @return disputeID ID of the dispute created.
     */
    function createDispute(uint256 _choices, bytes memory _extraData) public virtual requireArbitrationFee(_extraData) payable returns(uint256 disputeID) {}

    /** @dev Compute the cost of arbitration. It is recommended not to increase it often, as it can be highly time and gas consuming for the arbitrated contracts to cope with fee augmentation.
     *  @param _extraData Can be used to give additional info on the dispute to be created.
     *  @return fee Amount to be paid.
     */
    function arbitrationCost(bytes memory _extraData) public virtual view returns(uint256 fee);

    /** @dev Appeal a ruling. Note that it has to be called before the arbitrator contract calls rule.
     *  @param _disputeID ID of the dispute to be appealed.
     *  @param _extraData Can be used to give extra info on the appeal.
     */
    function appeal(uint256 _disputeID, bytes memory _extraData) public requireAppealFee(_disputeID,_extraData) payable {
        emit AppealDecision(_disputeID, Arbitrable(msg.sender));
    }

    /** @dev Compute the cost of appeal. It is recommended not to increase it often, as it can be higly time and gas consuming for the arbitrated contracts to cope with fee augmentation.
     *  @param _disputeID ID of the dispute to be appealed.
     *  @param _extraData Can be used to give additional info on the dispute to be created.
     *  @return fee Amount to be paid.
     */
    function appealCost(uint256 _disputeID, bytes memory _extraData) public virtual view returns(uint256 fee);

    /** @dev Compute the start and end of the dispute's current or next appeal period, if possible.
     *  @param _disputeID ID of the dispute.
     *  @return start The start of the period.
     *  @return end The end of the period.
     */
    function appealPeriod(uint256 _disputeID) public view returns(uint256 start, uint256 end) {}

    /** @dev Return the status of a dispute.
     *  @param _disputeID ID of the dispute to rule.
     *  @return status The status of the dispute.
     */
    function disputeStatus(uint256 _disputeID) public virtual view returns(DisputeStatus status);

    /** @dev Return the current ruling of a dispute. This is useful for parties to know if they should appeal.
     *  @param _disputeID ID of the dispute.
     *  @return ruling The ruling which has been given or the one which will be given if there is no appeal.
     */
    function currentRuling(uint256 _disputeID) public virtual view returns(uint256 ruling);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./Arbitrator.sol";

/** @title IArbitrable
 *  @author David Rivero
 *  Arbitrable interface.
 *  When developing arbitrable contracts, we need to:
 *  -Define the action taken when a ruling is received by the contract. We should do so in executeRuling.
 *  -Allow dispute creation. For this a function must:
 *      -Call arbitrator.createDispute.value(_fee)(_choices,_extraData);
 *      -Create the event Dispute(_arbitrator,_disputeID,_rulingOptions);
 */
interface IArbitrable {
    /** @dev To be emmited when meta-evidence is submitted.
     *  @param _metaEvidenceID Unique identifier of meta-evidence.
     *  @param _evidence A link to the meta-evidence JSON.
     */
    event MetaEvidence(uint indexed _metaEvidenceID, string _evidence);

    /** @dev To be emmited when a dispute is created to link the correct meta-evidence to the disputeID
     *  @param _arbitrator The arbitrator of the contract.
     *  @param _disputeID ID of the dispute in the Arbitrator contract.
     *  @param _metaEvidenceID Unique identifier of meta-evidence.
     *  @param _evidenceGroupID Unique identifier of the evidence group that is linked to this dispute.
     */
    event Dispute(Arbitrator indexed _arbitrator, uint indexed _disputeID, uint _metaEvidenceID, uint _evidenceGroupID);

    /** @dev To be raised when evidence are submitted. Should point to the ressource (evidences are not to be stored on chain due to gas considerations).
     *  @param _arbitrator The arbitrator of the contract.
     *  @param _evidenceGroupID Unique identifier of the evidence group the evidence belongs to.
     *  @param _party The address of the party submiting the evidence. Note that 0x0 refers to evidence not submitted by any party.
     *  @param _evidence A URI to the evidence JSON file whose name should be its keccak256 hash followed by .json.
     */
    event Evidence(Arbitrator indexed _arbitrator, uint indexed _evidenceGroupID, address indexed _party, string _evidence);

    /** @dev To be raised when a ruling is given.
     *  @param _arbitrator The arbitrator giving the ruling.
     *  @param _disputeID ID of the dispute in the Arbitrator contract.
     *  @param _ruling The ruling which was given.
     */
    event Ruling(Arbitrator indexed _arbitrator, uint indexed _disputeID, uint _ruling);

    /** @dev Give a ruling for a dispute. Must be called by the arbitrator.
     *  The purpose of this function is to ensure that the address calling it has the right to rule on the contract.
     *  @param _disputeID ID of the dispute in the Arbitrator contract.
     *  @param _ruling Ruling given by the arbitrator. Note that 0 is reserved for "Not able/wanting to make a decision".
     */
    function rule(uint _disputeID, uint _ruling) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IJobRegistry {
    enum Status {
        Intialized, 
        Confirmed,
        Finished,
        Rejected
    }
    
    struct Job {
        Status status;
        uint256 employerId;
        uint256 employeeId;
        uint256 initiatorId;
        string jobDataUri;
    }

    function getJob(uint256 _jobId) external view returns (Job memory);

    function afterDeposit(uint256 _jobId, uint256 _proposalId, uint256 _transactionId) external;

    function afterFullPayment(uint256 _jobId) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IArbitrable.sol";

/** @title Arbitrable
 *  @author David Rivero
 *  Arbitrable abstract contract.
 *  When developing arbitrable contracts, we need to:
 *  -Define the action taken when a ruling is received by the contract. We should do so in executeRuling.
 *  -Allow dispute creation. For this a function must:
 *      -Call arbitrator.createDispute.value(_fee)(_choices,_extraData);
 *      -Create the event Dispute(_arbitrator,_disputeID,_rulingOptions);
 */
abstract contract Arbitrable is IArbitrable {
    Arbitrator public arbitrator;
    bytes public arbitratorExtraData; // Extra data to require particular dispute and appeal behaviour.

    modifier onlyArbitrator {require(msg.sender == address(arbitrator), "Can only be called by the arbitrator."); _;}

    /** @dev Constructor. Choose the arbitrator.
     *  @param _arbitrator The arbitrator of the contract.
     *  @param _arbitratorExtraData Extra data for the arbitrator.
     */
    constructor(Arbitrator _arbitrator, bytes memory _arbitratorExtraData) {
        arbitrator = _arbitrator;
        arbitratorExtraData = _arbitratorExtraData;
    }

    /** @dev Give a ruling for a dispute. Must be called by the arbitrator.
     *  The purpose of this function is to ensure that the address calling it has the right to rule on the contract.
     *  @param _disputeID ID of the dispute in the Arbitrator contract.
     *  @param _ruling Ruling given by the arbitrator. Note that 0 is reserved for "Not able/wanting to make a decision".
     */
    function rule(uint _disputeID, uint _ruling) public override onlyArbitrator {
        emit Ruling(Arbitrator(msg.sender),_disputeID,_ruling);

        executeRuling(_disputeID,_ruling);
    }


    /** @dev Execute a ruling of a dispute.
     *  @param _disputeID ID of the dispute in the Arbitrator contract.
     *  @param _ruling Ruling given by the arbitrator. Note that 0 is reserved for "Not able/wanting to make a decision".
     */
    function executeRuling(uint _disputeID, uint _ruling) virtual internal;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}