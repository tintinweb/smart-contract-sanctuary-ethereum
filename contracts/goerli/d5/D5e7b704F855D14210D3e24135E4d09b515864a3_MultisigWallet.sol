// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

error MultisigWallet__NotValidSignatory();
error MultisigWallet__NotValidTxId();
error MultisigWallet__TxAlreadySigned();
error MultisigWallet__TxAlreadyExecuted();
error MultisigWallet__InvalidAdress();
error MultisigWallet__NonExistentSignatory();
error MultisigWallet__SignatoryAlreadyExists();
error MultisigWallet__SignatoryAlreadyUpvotedCandidate();
error MultisigWallet__SignatoryAlreadyDownvotedCandidate();

/** @title A MultiSigWallet contract
 * @notice This contract is to demo a sample multisig contract.
 * It can:
 * 1. Define the number of signatories required to execute a transaction.
 * 2. Define the list of signatories and their addresses.
 * 3. Add/remove signatories.
 * 4. Execute a transaction after the required number of signatures have been obtained.
 * 5. Cancel a transaction before it has been executed.
 */
contract MultisigWallet {
    event Submit(uint indexed txId);
    event Sign(address indexed owner, uint indexed txId);
    event Revoke(address indexed owner, uint indexed txId);
    event Execute(uint indexed txId);
    event Upvote(address indexed signatoryCandidate);
    event AddSignatory(address indexed signatoryCandidate);
    event Downvote(address indexed signatory);
    event RemoveSignatory(address indexed signatory);

    uint256 private requiredSignatures;
    address[] private signatories;

    mapping(address => bool) public isSignatory;

    struct Transaction {
        uint256 txId;
        address to;
        uint256 value;
        bytes data;
        uint256 numOfApprovals;
        bool executed;
    }

    Transaction[] private transactions;

    // address => txId => bool
    mapping(address => mapping(uint256 => bool)) public isSignedTxByAddress;

    // signatory => signatoryCandidate => bool
    mapping(address => mapping(address => bool))
        public approvedCandidateBySignatory;

    address[] private candidatesToAdd;

    // signatory => signatoryToRemove => bool
    mapping(address => mapping(address => bool))
        public approvedSignatoryRemovalBySignatory;

    address[] private signatoriesToRemove;

    modifier onlySignatory() {
        if (!isSignatory[msg.sender])
            revert MultisigWallet__NotValidSignatory();
        _;
    }

    modifier txExists(uint _txId) {
        if (_txId >= transactions.length) revert MultisigWallet__NotValidTxId();
        _;
    }

    modifier notSignedTx(uint _txId) {
        if (isSignedTxByAddress[msg.sender][_txId])
            revert MultisigWallet__TxAlreadySigned();
        _;
    }

    modifier notExecutedTx(uint _txId) {
        if (transactions[_txId].executed)
            revert MultisigWallet__TxAlreadyExecuted();
        _;
    }

    modifier notNullAddress(address _address) {
        if (_address == address(0)) revert MultisigWallet__InvalidAdress();
        _;
    }

    modifier signatoryExists(address _signatory) {
        if (!isSignatory[_signatory])
            revert MultisigWallet__NonExistentSignatory();
        _;
    }

    modifier signatoryNonExistent(address _signatoryCandidate) {
        if (isSignatory[_signatoryCandidate])
            revert MultisigWallet__SignatoryAlreadyExists();
        _;
    }
    modifier notUpvotedForCandidate(address _signatoryCandidate) {
        if (approvedCandidateBySignatory[msg.sender][_signatoryCandidate])
            revert MultisigWallet__SignatoryAlreadyUpvotedCandidate();
        _;
    }

    modifier notDownvotedForSignatory(address _signatory) {
        if (approvedSignatoryRemovalBySignatory[msg.sender][_signatory])
            revert MultisigWallet__SignatoryAlreadyDownvotedCandidate();
        _;
    }

    constructor(uint256 _requiredSignatures, address[] memory _signatories) {
        require(_signatories.length > 0, "signatories required");
        require(
            _requiredSignatures > 0 &&
                _requiredSignatures <= _signatories.length,
            "invalid value of required signatories"
        );
        requiredSignatures = _requiredSignatures;
        for (uint256 i; i < _signatories.length; i++) {
            address signatory = _signatories[i];
            require(signatory != address(0), "invalid signatory");
            require(!isSignatory[signatory], "signatory is already added");
            isSignatory[signatory] = true;
            signatories.push(signatory);
        }
    }

    function getRequiredSignatories() public view returns (uint256) {
        return requiredSignatures;
    }

    function getSignatories() public view returns (address[] memory) {
        return signatories;
    }

    function getTransaction(
        uint256 index
    ) public view returns (Transaction memory) {
        return transactions[index];
    }

    function getTransactions() public view returns (Transaction[] memory) {
        return transactions;
    }

    function getCandidatesToAdd() public view returns (address[] memory) {
        return candidatesToAdd;
    }

    function getSignatoriesToRemove() public view returns (address[] memory) {
        return signatoriesToRemove;
    }

    function _getUpvoteCandidateCount(
        address _signatoryCandidate
    ) private view returns (uint256 count) {
        for (uint256 i; i < signatories.length; i++) {
            if (
                approvedCandidateBySignatory[signatories[i]][
                    _signatoryCandidate
                ]
            ) {
                count += 1;
            }
        }
    }

    function _getDownvoteCandidateCount(
        address _signatory
    ) private view returns (uint256 count) {
        for (uint256 i; i < signatories.length; i++) {
            if (
                approvedSignatoryRemovalBySignatory[signatories[i]][_signatory]
            ) {
                count += 1;
            }
        }
    }

    function submitTx(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external payable onlySignatory {
        uint256 txId = transactions.length;

        transactions.push(
            Transaction({
                txId: txId,
                to: _to,
                value: _value,
                data: _data,
                numOfApprovals: 0,
                executed: false
            })
        );
        emit Submit(txId);
    }

    function signTx(
        uint256 _txId
    )
        external
        onlySignatory
        txExists(_txId)
        notSignedTx(_txId)
        notExecutedTx(_txId)
    {
        isSignedTxByAddress[msg.sender][_txId] = true;
        transactions[_txId].numOfApprovals += 1;
        emit Sign(msg.sender, _txId);
    }

    function executeTx(
        uint256 _txId
    ) external onlySignatory txExists(_txId) notExecutedTx(_txId) {
        require(
            transactions[_txId].numOfApprovals >= requiredSignatures,
            "not enough signatures"
        );
        Transaction storage transaction = transactions[_txId];
        transaction.executed = true;

        (bool success, ) = payable(transaction.to).call{
            value: transaction.value
        }(transaction.data);

        require(success, "tx failed");

        emit Execute(_txId);
    }

    function revokeTx(
        uint256 _txId
    ) external txExists(_txId) notExecutedTx(_txId) {
        require(
            isSignedTxByAddress[msg.sender][_txId],
            "tx not signed by this address"
        );
        isSignedTxByAddress[msg.sender][_txId] = false;
        transactions[_txId].numOfApprovals -= 1;
        emit Revoke(msg.sender, _txId);
    }

    function upvoteSignatoryCandidate(
        address _signatoryCandidate
    )
        external
        onlySignatory
        notNullAddress(_signatoryCandidate)
        signatoryNonExistent(_signatoryCandidate)
        notUpvotedForCandidate(_signatoryCandidate)
    {
        approvedCandidateBySignatory[msg.sender][_signatoryCandidate] = true;

        candidatesToAdd.push(_signatoryCandidate);

        emit Upvote(_signatoryCandidate);
    }

    function downvoteSignatory(
        address _signatory
    )
        external
        onlySignatory
        signatoryExists(_signatory)
        notDownvotedForSignatory(_signatory)
    {
        approvedSignatoryRemovalBySignatory[msg.sender][_signatory] = true;

        signatoriesToRemove.push(_signatory);

        emit Downvote(_signatory);
    }

    function addSignatory(
        address _signatoryCandidate
    ) external onlySignatory signatoryNonExistent(_signatoryCandidate) {
        require(
            _getUpvoteCandidateCount(_signatoryCandidate) >= requiredSignatures,
            "not enough signatures"
        );
        isSignatory[_signatoryCandidate] = true;
        signatories.push(_signatoryCandidate);
        requiredSignatures += 1;

        emit AddSignatory(_signatoryCandidate);
    }

    function removeSignatory(
        address _signatory
    ) external onlySignatory signatoryExists(_signatory) {
        require(
            _getDownvoteCandidateCount(_signatory) >= requiredSignatures,
            "not enough signatures"
        );

        address[] memory m_candidatesToAdd = candidatesToAdd;

        // Reset all upvotes/downvotes and signed tx done by this signatory
        for (uint256 i; i < m_candidatesToAdd.length; i++) {
            if (
                approvedCandidateBySignatory[_signatory][m_candidatesToAdd[i]]
            ) {
                approvedCandidateBySignatory[_signatory][
                    m_candidatesToAdd[i]
                ] = false;
            }
        }

        address[] memory m_signatoriesToRemove = signatoriesToRemove;

        for (uint256 i; i < m_signatoriesToRemove.length; i++) {
            if (
                approvedSignatoryRemovalBySignatory[_signatory][
                    m_signatoriesToRemove[i]
                ]
            ) {
                approvedSignatoryRemovalBySignatory[_signatory][
                    m_signatoriesToRemove[i]
                ] = false;
            }
        }

        Transaction[] memory m_transactions = transactions;

        for (uint256 i; i < m_transactions.length; i++) {
            if (isSignedTxByAddress[_signatory][m_transactions[i].txId]) {
                isSignedTxByAddress[_signatory][m_transactions[i].txId] = false;
                transactions[i].numOfApprovals -= 1;
            }
        }

        // Remove signatory from signatories
        address[] memory m_signatories = signatories;

        uint256 signatoryIndex = 0;
        for (uint256 i = 0; i < m_signatories.length; i++) {
            if (m_signatories[i] == _signatory) {
                signatoryIndex = i;
                break;
            }
        }

        for (uint i = signatoryIndex; i < signatories.length - 1; i++) {
            signatories[i] = signatories[i + 1];
        }

        signatories.pop();

        isSignatory[_signatory] = false;
        requiredSignatures -= 1;

        emit RemoveSignatory(_signatory);
    }
}