// SPDX-License-Identifier:  CC-BY-NC-4.0
// email "licensing [at] pyxelchain.com" for licensing information
pragma solidity =0.8.17;

//import "hardhat/console.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

interface IMultiSig {
    function initialize(address[] memory _signers, uint256 _signersNeeded, uint256 _fullConsensusNumber, uint256 _delay, uint256 _lifetime) external payable;
    function submitTx(address _to, uint256 _value, bytes memory _data) external returns (uint256);
    function approveTx(uint256 _id) external;
    function executeTx(uint256 _id) external;
    function rejectTx(uint256 _id) external;
    function getNextId() external view returns (uint256);
    function getApprovedTxSigs(uint256 _id) external view returns (address[] memory);
    function createUpdateSigners(address[] calldata _newSigners) external returns (uint256);
    function createSignersNeeded(uint256 _id) external returns (uint256);
    function createFullConsensusNumber(uint256 _id) external returns (uint256);
    function approveUpdateSigners(uint256 _id) external;
    function approveSignersNeeded(uint256 _id) external;
    function approveFullConsensusNumber(uint256 _id) external;
    function rejectRequest(uint256 _id) external;
    function getApprovedRqSigs(uint256 _id) external view returns (address[] memory);
    function getOldSigners(uint256 _id) external view returns (address[] memory);
    function getNewSigners(uint256 _id) external view returns (address[] memory);
    function getSigners() external view returns (address[] memory);
}

/**
 * @title A multisignature wallet
 * @notice You can use this contract to add an additional layer of security to your funds
 */
contract MultiSig is Initializable, IMultiSig, ERC165 {
    event TxSubmitted(
        uint256 indexed id,
        address indexed from,
        address indexed to,
        uint256 value,
        bytes data
    );

    event TxApproved(
        uint256 indexed id,
        address indexed from,
        uint256 approvals
    );

    event TxExecuted(
        uint256 indexed id,
        address indexed to,
        uint256 value,
        bytes data
    );

    event TxRejected(
        uint256 indexed id,
        address from,
        address to,
        uint256 value,
        bytes data
    );

    mapping(uint256 => mapping(address => bool)) public hasApproved;
    mapping(uint256 => bool) public txActive;
    Transaction[] public transactions;
    uint256[] public activeTransactionIds;

    struct Transaction {
        address[] approvedSignatures;
        address rejectedSignature;
        address to;
        uint256 value;
        bytes data;
        bool executed;
        bool rejected;
        uint256 approvalCount;
        uint256 blockNumber;
    }

    event RequestCreated(
        uint256 indexed id,
        address indexed from,
        RequestType indexed rtype
    );

    event RequestApproved(
        uint256 indexed id,
        address indexed from,
        RequestType indexed rtype,
        uint256 count
    );

    event RequestRejected(
        uint256 indexed id,
        address indexed from,
        RequestType indexed rtype
    );

    uint256 internal blockOffset;
    uint256 internal requestLifetime;

    address[] public signers;
    uint256 public signersNeeded;
    uint256 public fullConsensusNumber;

    mapping(address => bool) public activeSigners;
    mapping(uint256 => Request) public variableUpdateRequests;
    mapping(uint256 => mapping(address => bool)) public hasApprovedRequest;
    uint256 public variableUpdateIndex = 1;

    Request internal activeRequest;
    uint256 internal activeRequestId;

    enum RequestType {
        UpdateSigners,
        SignersNeeded,
        FullConsensusNumber
    }

    struct Request {
        RequestType requestType;
        address[] approvedSignatures;
        address rejectedSignature;
        uint256 blockNumber;
        uint256 oldCount;
        uint256 newCount;
        address[] oldSigners;
        address[] newSigners;
        uint256 approvedCount;
        bool completed;
        bool rejected;
    }

    // constructor() {
    // }

    function supportsInterface(bytes4 _interfaceId) public view virtual override returns (bool) {
        return _interfaceId == type(IMultiSig).interfaceId || super.supportsInterface(_interfaceId);
    }

    /**
     * @notice Initializes the contract, this is needed because we use a clone factory
     * @dev This method can only be called 1 time
     * @param _signers Is an array of signers to be used in the MultiSig wallet
     * @param _signersNeeded Is the number of signers needed to approve a normal transaction
     * @param _fullConsensusNumber Is the number of signers needed to change the variables in the contract
     * @param _delay Number of blocks to offset from a proposal creation to when votes can be cast
     * @param _lifetime Number of blocks to leave a proposal active before it is automatically terminated
     */
    function initialize(
        address[] memory _signers,
        uint256 _signersNeeded,
        uint256 _fullConsensusNumber,
        uint256 _delay,
        uint256 _lifetime
    ) public payable override initializer {
        require(_lifetime >= _delay + 15, "need longer lifetime");
        blockOffset = _delay;
        requestLifetime = _lifetime;
        require(_signersNeeded >= 1, "MS: Requires >= 1 signer");
        require(
            _signers.length >= _signersNeeded,
            "MS: signersNeeded <= total"
        );
        require(
            _signers.length >= _fullConsensusNumber,
            "MS: ConsensusNumber <= total"
        );
        for (uint256 i = 0; i < _signers.length; i++) {
            require(
                activeSigners[_signers[i]] == false,
                "MS: Duplicate in signers"
            );
            require(_signers[i] != address(0), "invalid address");
            activeSigners[_signers[i]] = true;
            signers.push(_signers[i]);
        }
        signersNeeded = _signersNeeded;
        fullConsensusNumber = _fullConsensusNumber;
    }

    /**
     * @notice receive ETH with no calldata
     * @dev see: https://blog.soliditylang.org/2020/03/26/fallback-receive-split/
     */
    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    /**
     * @notice receive ETH with no function match
     */
    fallback() external payable {}

    /**
     * @notice Submit a transaction for approval by rest of signers
     * @dev Ensures no active requests, _to address is valid and contract balance is high enough
     * @dev Then creates Transaction and adds to transactions array
     * @param _to Address that the transaction will be sent to upon approval
     * @param _value Amount of ether sent with transaction
     * @param _data If _to address is a contract, _data will contain encoded information about a callback function
     */
    function submitTx(
        address _to,
        uint256 _value,
        bytes memory _data
    ) external signersOnly override returns (uint256 _txIndex) {
        // Ensure there are no active update variable requests
        require(!_activeUpdateVariableRequest(), "pending request");

        // Checks if _to address is a contract or EOA
        uint32 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(_to)
        }
        require(_data.length == 0 || size > 0, "data on EOA");

        // Creates new transaction ID and sets it as active
        _txIndex = transactions.length;
        txActive[_txIndex] = true;
        activeTransactionIds.push(_txIndex);
        hasApproved[_txIndex][msg.sender] = true;

        address[] memory sigs = new address[](1);
        sigs[0] = msg.sender;

        // Add new transaction to transactions array
        transactions.push(
            Transaction({
                approvedSignatures: sigs,
                rejectedSignature: address(0),
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                rejected: false,
                approvalCount: 1,
                blockNumber: block.number
            })
        );

        emit TxSubmitted(_txIndex, msg.sender, _to, _value, _data);
    }

    /**
     * @notice Approve a pending transaction
     * @dev If transaction is valid, adds approval
     * @param _id Index of transaction in transactions array
     */
    function approveTx(uint256 _id)
        external
        signersOnly
        txExists(_id)
        isActive(_id)
        override
    {
        require(!hasApproved[_id][msg.sender], "already approved by caller");
        Transaction storage _tx = transactions[_id];
        require(block.number > _tx.blockNumber + blockOffset, "tx delayed");
        require(
            block.number < _tx.blockNumber + requestLifetime,
            "tx timed out"
        );

        // Add approval to transaction and record who approval came from
        _tx.approvalCount++;
        hasApproved[_id][msg.sender] = true;
        _tx.approvedSignatures.push(msg.sender);

        emit TxApproved(_id, msg.sender, _tx.approvalCount);
    }

    /**
     * @notice To be called by a signer to execute a transaction that has received enough approvals
     * @dev Sends transaction to specific address with msg.value = _tx.value
     * @param _id Index of transaction in transactions array
     */
    function executeTx(uint256 _id)
        external
        signersOnly
        txExists(_id)
        isActive(_id)
        override
    {
        Transaction storage _tx = transactions[_id];
        require(_tx.approvalCount >= signersNeeded, "not enough approvals");
        require(
            block.number < _tx.blockNumber + requestLifetime,
            "tx timed out"
        );

        // Mark tx as executed and remove from activeTransactions
        _tx.executed = true;
        _removeNum(activeTransactionIds, _id);
        txActive[_id] = false;

        // _tx.to.call sends transaction to specified address
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = _tx.to.call{value: _tx.value}(_tx.data);
        require(success, "transaction failed");

        emit TxExecuted(_id, _tx.to, _tx.value, _tx.data);
    }

    /**
     * @notice Reject a pending transaction
     * @dev Only one rejection is needed to cancel a transaction
     * @param _id Index of Transaction in transactions array
     */
    function rejectTx(uint256 _id)
        external
        signersOnly
        txExists(_id)
        isActive(_id)
        override
    {
        Transaction storage _tx = transactions[_id];
        _tx.rejected = true;
        _tx.rejectedSignature = msg.sender;
        _removeNum(activeTransactionIds, _id);
        txActive[_id] = false;

        emit TxRejected(_id, msg.sender, _tx.to, _tx.value, _tx.data);
    }

    /**
     * @notice Clear timed out transactions out of the activeTransactionIds list
     */
    function cleanUpActiveTxs() external {
        uint256 i = 0;
        while (i < activeTransactionIds.length) {
            uint256 _index = activeTransactionIds[i];
            Transaction storage _tx = transactions[_index];
            if (block.number > _tx.blockNumber + requestLifetime) {
                _removeNum(activeTransactionIds, _index);
                txActive[_index] = false;
            } else i++;
        }
    }

    /**
     * @notice Returns current length of transactions array which will be ID of next transaction
     */
    function getNextId() external view override returns (uint256) {
        return transactions.length;
    }

    /**
     * @notice Returns full array of approved signatures for specific transaction
     * @param _id Index of transaction in transactions array
     */
    function getApprovedTxSigs(uint256 _id)
        external
        view
        override
        returns (address[] memory)
    {
        return transactions[_id].approvedSignatures;
    }

    /**
     * @notice Returns true if transaction has timed out, false if not
     * @param _id Index of transaction in transactions array
     */
    function _hasTimedOut(uint256 _id) private view returns (bool) {
        Transaction storage _tx = transactions[_id];
        return block.number > _tx.blockNumber + requestLifetime;
    }

    /**
     * @notice Checks all transactions listed as active and will revert if any are still active
     */
    function _checkActiveTxs() private view {
        for (uint256 i = 0; i < activeTransactionIds.length; i++) {
            uint256 _index = activeTransactionIds[i];
            require(_hasTimedOut(_index), "pending txs");
        }
    }

    /**
     * @dev Removes a number from a list
     * @dev Does not check for duplicates
     */
    function _removeNum(uint256[] storage _list, uint256 _num) private {
        for (uint256 i = 0; i < _list.length; i++) {
            if (_list[i] == _num) {
                _list[i] = _list[_list.length - 1];
                _list.pop();
                break;
            }
        }
    }

    // MODIFIERS

    /**
     * @dev Reverts if _id is larger than length of transactions array
     * @param _id Index of transaction in transactions array
     */
    modifier txExists(uint256 _id) {
        require(_id < transactions.length, "transaction does not exist");
        _;
    }

    /**
     * @dev Reverts if transaction is not marked as active in txActive mapping
     * @param _id Index of transaction in transactions array
     */
    modifier isActive(uint256 _id) {
        require(txActive[_id], "tx complete");
        _;
    }

    /**
     * @notice Create a request to update the signers array
     * @dev Can only be called if no pending transactions or other update variable requests
     * @param _newSigners Array of suggested new signer addresses
     */
    function createUpdateSigners(address[] calldata _newSigners)
        public
        signersOnly
        override
        returns (uint256 _id)
    {
        _checkActiveTxs();
        if (activeTransactionIds.length > 0) delete activeTransactionIds;
        require(!_activeUpdateVariableRequest(), "other request active");
        require(_newSigners.length > 1, "need more signers");
        require(_uniqueArray(_newSigners), "no duplicates");
        _id = variableUpdateIndex;
        Request storage _request = variableUpdateRequests[_id];
        _request.requestType = RequestType.UpdateSigners;
        _request.oldSigners = signers;
        _request.newSigners = _newSigners;
        _request.approvedSignatures.push(msg.sender);
        _request.approvedCount++;
        _request.blockNumber = block.number;
        variableUpdateIndex++;
        activeRequest = _request;
        activeRequestId = _id;
        hasApprovedRequest[_id][msg.sender] = true;

        emit RequestCreated(_id, msg.sender, RequestType.UpdateSigners);
    }

    /**
     * @notice Create a request to update the signersNeeded variable
     * @dev Can only be called if no other transaction or request is pending
     * @param _newCount Suggested new value for signersNeeded
     */
    function createSignersNeeded(uint256 _newCount)
        public
        signersOnly
        override
        returns (uint256 _id)
    {
        _checkActiveTxs();
        if (activeTransactionIds.length > 0) delete activeTransactionIds;
        require(_newCount <= signers.length, "too high");
        require(_newCount != signersNeeded, "enter new number");
        require(!_activeUpdateVariableRequest(), "other request active");
        _id = variableUpdateIndex;
        Request storage _request = variableUpdateRequests[_id];
        _request.requestType = RequestType.SignersNeeded;
        _request.oldCount = signersNeeded;
        _request.approvedSignatures.push(msg.sender);
        _request.newCount = _newCount;
        _request.approvedCount++;
        _request.blockNumber = block.number;
        variableUpdateIndex++;
        activeRequest = _request;
        activeRequestId = _id;
        hasApprovedRequest[_id][msg.sender] = true;

        emit RequestCreated(_id, msg.sender, RequestType.SignersNeeded);
    }


    /**
     * @notice To be called by a signer that wants to update the fullConsensusNumber variable
     * @dev Creates a request to update fullConsensusNumber
     * @param _newCount Suggested new value for fullConsensusNumber
     */
    function createFullConsensusNumber(uint256 _newCount)
        public
        signersOnly
        override
        returns (uint256 _id)
    {
        _checkActiveTxs();
        if (activeTransactionIds.length > 0) delete activeTransactionIds;
        require(_newCount <= signers.length, "too high");
        require(_newCount != fullConsensusNumber, "enter new number");
        require(!_activeUpdateVariableRequest(), "other request active");
        _id = variableUpdateIndex;
        Request storage _request = variableUpdateRequests[_id];
        _request.requestType = RequestType.FullConsensusNumber;
        _request.oldCount = fullConsensusNumber;
        _request.approvedSignatures.push(msg.sender);
        _request.newCount = _newCount;
        _request.approvedCount++;
        _request.blockNumber = block.number;
        variableUpdateIndex++;
        activeRequest = _request;
        activeRequestId = _id;
        hasApprovedRequest[_id][msg.sender] = true;

        emit RequestCreated(_id, msg.sender, RequestType.FullConsensusNumber);
    }

    /**
     * @notice To be called by a signer that wants to approve an updateSigners request
     * @dev Adds approval to updateSigners request and updates the signers array if enough approvals are received
     * @param _id ID of Request
     */
    function approveUpdateSigners(uint256 _id)
        external
        signersOnly
        requestExists(_id)
        isActiveRequest(_id)
        notApproved(_id)
        override
    {
        Request storage _request = variableUpdateRequests[_id];
        require(
            _request.requestType == RequestType.UpdateSigners,
            "not update signers request"
        );
        require(
            block.number > _request.blockNumber + blockOffset,
            "request delayed"
        );
        require(
            block.number < _request.blockNumber + requestLifetime,
            "request timed out"
        );
        _request.approvedSignatures.push(msg.sender);
        _request.approvedCount++;
        hasApprovedRequest[_id][msg.sender] = true;

        emit RequestApproved(
            _id,
            msg.sender,
            RequestType.UpdateSigners,
            _request.approvedCount
        );

        if (_request.approvedCount >= fullConsensusNumber) {
            delete activeRequestId;
            delete activeRequest;
            _request.completed = true;

            // Update active signers
            for (uint256 i = 0; i < signers.length; i++) {
                activeSigners[signers[i]] = false;
            }
            for (uint256 i = 0; i < _request.newSigners.length; i++) {
                activeSigners[_request.newSigners[i]] = true;
            }

            signers = _request.newSigners;

            uint256 _length = signers.length;
            signersNeeded = _length < signersNeeded ? _length : signersNeeded;
            fullConsensusNumber = _length < fullConsensusNumber
                ? _length
                : fullConsensusNumber;
        }
    }

    /**
     * @notice To be called by a signer that wants to approve a signersNeeded request
     * @dev Adds approval to signersNeeded request and updates signersNeeded variable if enough approvals are received
     * @param _id ID of Request
     */
    function approveSignersNeeded(uint256 _id)
        external
        signersOnly
        requestExists(_id)
        isActiveRequest(_id)
        notApproved(_id)
        override
    {
        Request storage _request = variableUpdateRequests[_id];
        require(
            _request.requestType == RequestType.SignersNeeded,
            "not signers needed request"
        );
        require(
            block.number > _request.blockNumber + blockOffset,
            "request delayed"
        );
        require(
            block.number < _request.blockNumber + requestLifetime,
            "request timed out"
        );
        _request.approvedSignatures.push(msg.sender);
        _request.approvedCount++;
        hasApprovedRequest[_id][msg.sender] = true;

        emit RequestApproved(
            _id,
            msg.sender,
            RequestType.SignersNeeded,
            _request.approvedCount
        );

        if (_request.approvedCount >= fullConsensusNumber) {
            delete activeRequestId;
            delete activeRequest;
            _request.completed = true;
            signersNeeded = _request.newCount;
        }
    }

    /**
     * @notice To be called by a signer that wants to approve a fullConsensusNumber request
     * @dev Adds approval to fullConsensusNumber request and updates fullConsensusNumber if enough approvals are received
     * @param _id ID of Request
     */
    function approveFullConsensusNumber(uint256 _id)
        external
        signersOnly
        requestExists(_id)
        isActiveRequest(_id)
        notApproved(_id)
        override
    {
        Request storage _request = variableUpdateRequests[_id];
        require(
            _request.requestType == RequestType.FullConsensusNumber,
            "not full consensus request"
        );
        require(
            block.number > _request.blockNumber + blockOffset,
            "request delayed"
        );
        require(
            block.number < _request.blockNumber + requestLifetime,
            "request timed out"
        );
        _request.approvedSignatures.push(msg.sender);
        _request.approvedCount++;
        hasApprovedRequest[_id][msg.sender] = true;

        emit RequestApproved(
            _id,
            msg.sender,
            RequestType.FullConsensusNumber,
            _request.approvedCount
        );

        if (_request.approvedCount >= fullConsensusNumber) {
            delete activeRequestId;
            delete activeRequest;
            _request.completed = true;
            fullConsensusNumber = _request.newCount;
        }
    }

    /**
     * @notice To be called by a signer who wants to reject a variable update request
     * @dev Only one rejection needed to cancel request
     * @param _id ID of request to cancel
     */
    function rejectRequest(uint256 _id)
        external
        signersOnly
        requestExists(_id)
        isActiveRequest(_id)
        override
    {
        Request storage _request = variableUpdateRequests[_id];
        _request.rejected = true;
        _request.rejectedSignature = msg.sender;
        delete activeRequest;
        delete activeRequestId;

        emit RequestRejected(_id, msg.sender, _request.requestType);
    }

    /**
     * @notice Returns full array of approved signatures for specific variable update request
     * @param _id ID of request
     */
    function getApprovedRqSigs(uint256 _id)
        external
        view
        override
        returns (address[] memory)
    {
        return variableUpdateRequests[_id].approvedSignatures;
    }

    /**
     * @notice Returns full array of old signers for specific update signers request
     * @param _id ID of request
     */
    function getOldSigners(uint256 _id)
        external
        view
        override
        returns (address[] memory)
    {
        return variableUpdateRequests[_id].oldSigners;
    }

    /**
     * @notice Returns full array of new signers for specific update signers request
     * @param _id ID of request
     */
    function getNewSigners(uint256 _id)
        external
        view
        override
        returns (address[] memory)
    {
        return variableUpdateRequests[_id].newSigners;
    }

    /**
     * @notice Returns full array of signers
     */
    function getSigners()
        external
        view
        override
        returns (address[] memory)
    {
        return signers;
    }

    /**
     * @notice Called from createUpdateSigners()
     * @dev Checks if every element in array is unique
     * @param _arr Input array of addresses
     * @return true if array is unique, false if it contains duplicates
     */
    function _uniqueArray(address[] memory _arr) private pure returns (bool) {
        address[] memory _dup = new address[](_arr.length);
        for (uint256 i = 0; i < _arr.length; i++) {
            for (uint256 j = 0; j < _dup.length; j++) {
                if (_arr[i] == _dup[j]) return false;
            }
            _dup[i] = _arr[i];
        }
        return true;
    }

    /**
     * @notice Called from all functions creating transaction or request
     * @dev Returns true if there is an active update variable request
     * @dev If no active request was created, blockNum = 0 and this check is still valid (as long as blockchain is old enough)
     */
    function _activeUpdateVariableRequest() internal view returns (bool) {
        uint256 blockNum = activeRequest.blockNumber;
        return block.number < blockNum + requestLifetime;
    }

    // MODIFIERS

    /**
     * @dev Reverts if msg.sender is not a signer
     */
    modifier signersOnly() {
        require(activeSigners[msg.sender] == true, "caller is not a signer");
        _;
    }

    /**
     * @dev Reverts if request is not active
     * @param _id ID of request
     */
    modifier isActiveRequest(uint256 _id) {
        require(_id == activeRequestId, "request not active");
        _;
    }

    /**
     * @dev Reverts if request has already been approved by msg.sender
     * @param _id ID of request
     */
    modifier notApproved(uint256 _id) {
        require(
            !hasApprovedRequest[_id][msg.sender],
            "already approved by caller"
        );
        _;
    }

    /**
     * @dev Reverts if request does not exist
     * @param _id ID of request
     */
    modifier requestExists(uint256 _id) {
        require(_id < variableUpdateIndex, "request does not exist");
        _;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}