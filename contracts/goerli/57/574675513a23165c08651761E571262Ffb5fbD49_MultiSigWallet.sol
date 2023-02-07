// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract MultiSigWallet {
    event Submit(uint indexed txId);
    event Sign(address indexed owner, uint indexed txId);
    event Revoke(address indexed owner, uint indexed txId);
    event Execute(uint indexed txId);
    event Upvote(address indexed signatoryCandidate);
    event AddSignatory(address indexed signatoryCandidate);
    event Downvote(address indexed signatory);
    event RemoveSignatory(address indexed signatory);

    uint256 public requiredSignatures;
    address[] public signatories;

    mapping(address => bool) public isSignatory;

    struct Transaction {
        uint256 txId;
        address to;
        uint256 value;
        bytes data;
        uint256 numOfApprovals;
        bool executed;
    }

    Transaction[] public transactions;

    // address => txId => bool
    mapping(address => mapping(uint256 => bool)) public signedTxByAddress;

    // signatory => signatoryCandidate => bool
    mapping(address => mapping(address => bool))
        public approvedCandidateBySignatory;

    address[] candidatesToAdd;

    // signatory => signatoryToRemove => bool
    mapping(address => mapping(address => bool))
        public approvedSignatoryRemovalBySignatory;

    address[] signatoriesToRemove;

    modifier onlySignatory() {
        require(isSignatory[msg.sender], "not a valid signatory");
        _;
    }

    modifier txExists(uint _txId) {
        require(_txId < transactions.length, "tx does not exist");
        _;
    }

    modifier notSignedTx(uint _txId) {
        require(!signedTxByAddress[msg.sender][_txId], "tx already signed");
        _;
    }

    modifier notExecutedTx(uint _txId) {
        require(!transactions[_txId].executed, "tx already executed");
        _;
    }

    modifier notNullAddress(address _address) {
        require(_address != address(0), "invalid address");
        _;
    }

    modifier signatoryExists(address _signatory) {
        require(isSignatory[_signatory], "not a valid signatory");
        _;
    }

    modifier signatoryNonExistent(address _signatoryCandidate) {
        require(!isSignatory[_signatoryCandidate], "signatory already exists");
        _;
    }

    modifier notUpvotedForCandidate(address _signatoryCandidate) {
        require(
            !approvedCandidateBySignatory[msg.sender][_signatoryCandidate],
            "signatory already upvoted this candidate"
        );
        _;
    }

    modifier notDownvotedForSignatory(address _signatory) {
        require(
            !approvedSignatoryRemovalBySignatory[msg.sender][_signatory],
            "signatory already downvoted this signatory"
        );
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

    function submitTx(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external onlySignatory {
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
        signedTxByAddress[msg.sender][_txId] = true;
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

        (bool success, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );

        require(success, "tx failed");

        emit Execute(_txId);
    }

    function revokeTx(
        uint256 _txId
    ) external onlySignatory txExists(_txId) notExecutedTx(_txId) {
        require(
            signedTxByAddress[msg.sender][_txId],
            "tx not signed by this address"
        );
        signedTxByAddress[msg.sender][_txId] = false;
        transactions[_txId].numOfApprovals -= 1;
        emit Revoke(msg.sender, _txId);
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
    )
        external
        onlySignatory
        notNullAddress(_signatoryCandidate)
        signatoryNonExistent(_signatoryCandidate)
    {
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

        // Reset all upvotes/downvotes and signed tx done by this signatory
        for (uint256 i; i < candidatesToAdd.length; i++) {
            approvedCandidateBySignatory[_signatory][
                candidatesToAdd[i]
            ] = false;
        }

        for (uint256 i; i < signatoriesToRemove.length; i++) {
            approvedSignatoryRemovalBySignatory[_signatory][
                signatoriesToRemove[i]
            ] = false;
        }

        for (uint256 i; i < transactions.length; i++) {
            signedTxByAddress[_signatory][transactions[i].txId] = false;
            transactions[i].numOfApprovals -= 1;
        }

        // Remove signatory from signatories
        uint256 signatoryIndex = 0;
        for (uint256 i = 0; i < signatories.length; i++) {
            if (signatories[i] == _signatory) {
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