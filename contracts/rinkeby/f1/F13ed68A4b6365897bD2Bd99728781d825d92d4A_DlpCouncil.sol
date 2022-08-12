// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./DlpDaoCore.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract DlpCouncil is DlpDaoCore {
    event TreasuryRatioUpdate(string[] indexed types, uint256[] indexed ratios);

    event SubmitTransaction(
        address indexed owner,
        uint256 indexed txIndex,
        address indexed to,
        uint256 value,
        bytes data
    );
    event AuditTransaction(
        address indexed owner,
        uint256 indexed txIndex,
        bool result
    );
    event ExecuteTransaction(address indexed owner, uint256 indexed txIndex);

    // mapping from tx txIndex => owner => bool
    mapping(uint256 => mapping(address => bool)) public isConfirmed;

    // mapping from tx txIndex =>nextProposalId
    mapping(uint256 => uint256) public txIndexToProposaId;

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool pass;
        bool refuse;
        bool executed;
        uint256 passNum;
        uint256 refuseNum;
    }

    Transaction[] public transactions;

    modifier onlyCouncil() {
        require(isCouncil[msg.sender], "DLP201");
        _;
    }
    modifier txExists(uint256 _txIndex) {
        require(_txIndex < transactions.length, "DLP202");
        _;
    }
    modifier notExecuted(uint256 _txIndex) {
        require(!transactions[_txIndex].executed, "DLP203");
        _;
    }
    modifier notConfirmed(uint256 _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "DLP204");
        _;
    }
    modifier notRefuse(uint256 _txIndex) {
        require(!transactions[_txIndex].refuse, "DLP205");
        _;
    }
     modifier notPass(uint256 _txIndex) {
        require(!transactions[_txIndex].pass, "DLP206");
        _;
    }
    modifier txPass(uint256 _txIndex) {
        require(transactions[_txIndex].pass, "DLP207");
        _;
    }

    modifier notProposalTxIndex(uint256 _txIndex) {
        uint256 proposalId = txIndexToProposaId[_txIndex];
        require(proposalId == 0, "DLP208");
        _;
    }

    modifier proposalIsSubmit(uint256 _proposalId) {
        Proposal memory _pro = proposals[_proposalId];
        require(
            _pro.councilFlags[0] && !_pro.executed && !_pro.councilFlags[1],
            "DLP209"
        );
        require(_now256() < _pro.updateExpireTime, "DLP210");
        _;
    }

    modifier proposalIsConfirm(uint256 _txIndex) {
        uint256 _proposalId = txIndexToProposaId[_txIndex];
        require(_proposalId > 0, "DLP215");
        Proposal memory _pro = proposals[_proposalId];
        require(!_pro.executed && _pro.councilFlags[1], "DLP216");
        require(_now256() < _pro.auditExpireTime, "DLP217");
        require(!_pro.councilFlags[2] && !_pro.councilFlags[3], "DLP218");
        _;
    }
    modifier proposalIsExecute(uint256 _txIndex) {
        uint256 _proposalId = txIndexToProposaId[_txIndex];
        require(_proposalId > 0, "DLP215");
        Proposal memory _pro = proposals[_proposalId];
        require(_pro.councilFlags[2] && !_pro.executed, "DLP219");
        require(!_pro.safeFlags[0] && !_pro.safeFlags[1], "DLP220");
        require(_now256() > _pro.deadline, "DLP221");
        _;
    }

    constructor(address _securityCouncil) DlpDaoCore(_securityCouncil) {
    }

    function submitTransaction(
        address _to,
        uint256 _value,
        bytes memory _data,
        uint256 _proposalId,
        string memory _ipfsUrl
    ) public onlyCouncil nonReentrant proposalIsSubmit(_proposalId) {
        Proposal storage _proposal = proposals[_proposalId];
        _proposal.councilFlags[1] = true;
        _proposal.ipfsUrl = _ipfsUrl;
        uint256 txIndex = transactions.length;
        txIndexToProposaId[txIndex] = _proposalId;
        isConfirmed[txIndex][msg.sender] = true;
        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                pass: false,
                refuse: false,
                executed: false,
                passNum: 1,
                refuseNum: 0
            })
        );
        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
    }

    function auditTransaction(uint256 _txIndex, bool _result)
        public
        onlyCouncil
        txExists(_txIndex)
        notRefuse(_txIndex)
        notPass(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
        proposalIsConfirm(_txIndex)
    {
        uint256 _proposalId = txIndexToProposaId[_txIndex];
        _auditTransaction(_txIndex, _result);
        Transaction memory transaction = transactions[_txIndex];
        Proposal storage _proposal = proposals[_proposalId];
        if (transaction.pass) {
            _proposal.councilFlags[2] = true;
        }
        if (transaction.refuse) {
            _proposal.councilFlags[3] = true;
        }
        emit AuditTransaction(msg.sender, _txIndex, _result);
    }

    function executeTransaction(uint256 _txIndex)
        public
        onlyCouncil
        txExists(_txIndex)
        notExecuted(_txIndex)
        txPass(_txIndex)
        proposalIsExecute(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        uint256 _proposalId = txIndexToProposaId[_txIndex];
        Proposal storage _proposal = proposals[_proposalId];
        _proposal.executed = true;
        transaction.executed = true;
        _beforeExecute(transaction.to, transaction.value, transaction.data);
        _execute(transaction.to, transaction.value, transaction.data);
        _afterExecute(transaction.to, transaction.value, transaction.data);

        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    function auditTransactionExt(uint256 _txIndex, bool _result)
        public
        onlyCouncil
        txExists(_txIndex)
        notRefuse(_txIndex)
        notPass(_txIndex)
        notExecuted(_txIndex)
        notConfirmed(_txIndex)
        notProposalTxIndex(_txIndex)
    {
        _auditTransaction(_txIndex, _result);
        emit AuditTransaction(msg.sender, _txIndex, _result);
    }

    function executeTransactionExt(uint256 _txIndex)
        public
        onlyCouncil
        txExists(_txIndex)
        notExecuted(_txIndex)
        txPass(_txIndex)
        notProposalTxIndex(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];
        transaction.executed = true;
        _beforeExecute(transaction.to, transaction.value, transaction.data);
        _execute(transaction.to, transaction.value, transaction.data);
        _afterExecute(transaction.to, transaction.value, transaction.data);

        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    function transferToken(
        address _treasury,
        string memory _name,
        address _to,
        address _token,
        uint256 _amount
    ) public onlyCouncil returns (uint256) {
        // bytes4(keccak256(bytes('transferToken(string,address,address,uint256)')));
        bytes memory data = abi.encodeWithSelector(
            0x73d7ee7f,
            _name,
            _to,
            _token,
            _amount
        );
        uint256 txIndex = transactions.length;
        isConfirmed[txIndex][msg.sender] = true;
        transactions.push(
            Transaction({
                to: _treasury,
                value: 0,
                data: data,
                pass: false,
                refuse: false,
                executed: false,
                passNum: 1,
                refuseNum: 0
            })
        );

        emit SubmitTransaction(msg.sender, txIndex, _to, _amount, data);

        return txIndex;
    }

    function _auditTransaction(uint256 _txIndex, bool _result)
        internal
        virtual
    {
        Transaction storage transaction = transactions[_txIndex];
        isConfirmed[_txIndex][msg.sender] = true;
        if (_result) {
            transaction.passNum += 1;
            if (transaction.passNum >= threshold) {
                transaction.pass = true;
            }
        } else {
            transaction.refuseNum += 1;
            if (transaction.refuseNum >= threshold) {
                transaction.refuse = true;
            }
        }
    }

    /**
     * @dev Internal execution mechanism. Can be overridden to implement different execution mechanism
     */
    function _execute(
        address _target,
        uint256 _values,
        bytes memory _calldata
    ) internal virtual {
        string memory errorMessage = " call reverted without message";

        (bool success, bytes memory returndata) = _target.call{value: _values}(
            _calldata
        );
        Address.verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Hook before execution is triggered.
     */
    function _beforeExecute(
        address _targets,
        uint256 _values,
        bytes memory _calldata
    ) internal virtual {}

    /**
     * @dev Hook after execution is triggered.
     */
    function _afterExecute(
        address _targets,
        uint256 _values,
        bytes memory _calldata
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {Timestamp} from "../lib//Timestamp.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DlpDaoCore is ReentrancyGuard, Timestamp {
    event LogNewProposalId(
        uint256 indexed proposal_id,
        address indexed user,
        ProposalUserType indexed userType
    );
    event LogUpdateProposal(
        uint256 indexed proposal_id,
        string indexed ipfUrl,
        string indexed ipfsUrl
    );
    event AddCouncil(
        uint256 indexed _proposalId,
        string indexed ipfUrl,
        address[] owners
    );
    event ChangeCouncil(
        uint256 indexed _proposalId,
        string indexed ipfUrl,
        address oldOwner,
        address owner
    );
    event RemovedCouncil(
        uint256 indexed _proposalId,
        string indexed ipfUrl,
        address owner
    );

    event SafeCouncilAudit(
        address indexed owner,
        uint256 indexed proposalId,
        bool result
    );
    event SafeCouncilPause(address indexed owner, uint256 indexed proposalId);
    event SafeCouncilRest(address indexed owner, uint256 indexed proposalId);

    enum ProposalUserType {
        SAFECOUNCIL,
        COUNCIL
    }

    //Proposal id
    uint256 public nextProposalId = 1;

    // SafeCouncil function
    struct SafeProposal {
        bool[2] flags; //[start,executed];
        // Proposal IPFs address
        string ipfsUrl;
        // Expiration time of safety committee audit
        uint256 deadline;
    }
    //nextProposalId=>SafeProposal
    mapping(uint256 => SafeProposal) public safeProposals;
    //SafeProposal  array
    uint256[] internal safeProposalIds;

    // createProposalId function
    struct Proposal {
        address applicant;
        //Operation status of safety committee
        bool[3] safeFlags; //[refuse,stop,pass];
        // Operation status of council members
        bool[4] councilFlags; //[start,submit,pass,refuse];
        // Whether the proposal is implemented
        bool executed;
        // Proposal IPFs address
        string ipfsUrl;
        // Expiration time of safety committee audit
        uint256 deadline;
        // Expiration time of council member operation
        uint256 updateExpireTime;
        // Expiration time of approval by members of the Council
        uint256 auditExpireTime;
    }
    //
    uint256 public updateExpire = 3 days;
    //
    uint256 public auditExpire = 5 days;
    // Proposal duration
    uint256 public proposalTime = 7 days;

    //nextProposalId=>Proposal
    mapping(uint256 => Proposal) public proposals;
    //user=>nextProposalIds
    mapping(address => uint256[]) public userProposals;
    //proposal array
    uint256[] internal proposalIds;

    //council array
    address[] internal councils;
    //Council member already exists
    mapping(address => bool) public isCouncil;
    //
    uint256 internal ownerCount;
    //Approved personnel
    uint256 threshold;

    //Security Council wallet address
    address public securityCouncil;

    modifier securityAuthorized() {
        require(
            securityCouncil != address(0) && msg.sender == securityCouncil,
            "DLP100"
        );
        _;
    }
    modifier safeCouncilIsExecuted(uint256 _proposalId) {
        SafeProposal memory _pro = safeProposals[_proposalId];
        require(_pro.flags[0] && !_pro.flags[1], "DLP101");
        require(_now256() <= _pro.deadline, "DLP104");
        _;
    }
    modifier proposalSafeCouncilIsExecute(uint256 _proposalId) {
        Proposal memory _pro = proposals[_proposalId];
        require(_pro.councilFlags[2] && !_pro.executed, "DLP102");
        require(
            !_pro.safeFlags[0] && !_pro.safeFlags[1] && !_pro.safeFlags[2],
            "DLP103"
        );
        require(_now256() <= _pro.deadline, "DLP104");
        _;
    }

    modifier proposalSafeCouncilIsRest(uint256 _proposalId) {
        Proposal memory _pro = proposals[_proposalId];
        require(_pro.councilFlags[2] && !_pro.executed, "DLP102");
        require(
            !_pro.safeFlags[0] && _pro.safeFlags[1] && !_pro.safeFlags[2],
            "DLP105"
        );
        _;
    }

    constructor(address _securityCouncil) {
        require(_securityCouncil != address(0), "DLP106");
        securityCouncil = _securityCouncil;
    }

    //The ID of the newly-created proposal, which is created sequentially
    ///@return  Return proposal ID
    function createProposalId() public nonReentrant returns (uint256) {
        require(
            msg.sender != address(0) && msg.sender != address(this),
            "DLP110"
        );
        uint256 id = _createProposalId();
        bool[3] memory _safeFlags; //[refuse,stop,pass];
        bool[4] memory _councilFlags; //[start,submit,pass,refuse];
        _councilFlags[0] = true;
        Proposal memory _pro = Proposal({
            applicant: msg.sender,
            safeFlags: _safeFlags,
            councilFlags: _councilFlags,
            executed: false,
            ipfsUrl: "",
            deadline: _now256() + proposalTime,
            updateExpireTime: _now256() + updateExpire,
            auditExpireTime: _now256() + auditExpire
        });
        proposals[id] = _pro;
        userProposals[msg.sender].push(id);
        proposalIds.push(id);
        emit LogNewProposalId(id, msg.sender, ProposalUserType.COUNCIL);
        return id;
    }

    function _createProposalId() public returns (uint256) {
        uint256 _id = nextProposalId;
        nextProposalId = _id + 1;
        return _id;
    }

    function createSafeProposalId()
        public
        nonReentrant
        securityAuthorized
        returns (uint256)
    {
        uint256 id = _createProposalId();
        bool[2] memory _flags;
        _flags[0] = true;
        SafeProposal memory _pro = SafeProposal({
            flags: _flags,
            ipfsUrl: "",
            deadline: _now256() + proposalTime
        });
        safeProposals[id] = _pro;
        safeProposalIds.push(id);
        emit LogNewProposalId(id, msg.sender, ProposalUserType.SAFECOUNCIL);
        return id;
    }

    ///@param _ipfsUrl  IPFs url
    function _safeCouncilUpdate(uint256 _proposalId, string memory _ipfsUrl)
        internal
    {
        require(bytes(_ipfsUrl).length > 0, "DLP112");
        SafeProposal storage _pro = safeProposals[_proposalId];
        _pro.ipfsUrl = _ipfsUrl;
        _pro.flags[1] = true;
    }

    // Number formula adopted by the Council
    function _updateThreshold() internal {
        threshold = (ownerCount / 2) + 1;
    }

    //Adding the Council list can only be implemented by the security committee
    ///@param _proposalId   Proposal ID
    ///@param _ipfsUrl   ipfs url
    ///@param _councils      Address of board members
    function addCouncils(
        uint256 _proposalId,
        string memory _ipfsUrl,
        address[] memory _councils
    )
        public
        nonReentrant
        securityAuthorized
        safeCouncilIsExecuted(_proposalId)
    {
        require(_councils.length > 0, "DLP112");
        // The address and execution status of the proposal shall be updated
        _safeCouncilUpdate(_proposalId, _ipfsUrl);
        if (ownerCount > 0) {
            delete councils;
            ownerCount = 0;
        }
        for (uint256 i = 0; i < _councils.length; i++) {
            // Owner address cannot be null.
            address owner = _councils[i];
            require(owner != address(0) && owner != address(this), "DLP116");
            require(!isCouncil[owner], "DLP117");
            isCouncil[owner] = true;
            councils.push(owner);
        }
        ownerCount = councils.length;
        _updateThreshold();
        emit AddCouncil(_proposalId, _ipfsUrl, _councils);
    }

    //Updating the membership of the Council can only be implemented by the security committee
    ///@param _proposalId   Proposal ID
    ///@param _ipfsUrl   ipfs url
    ///@param _oldOwner      Old address
    ///@param _newOwner      new address
    function updateCouncil(
        uint256 _proposalId,
        string memory _ipfsUrl,
        address _oldOwner,
        address _newOwner
    )
        public
        nonReentrant
        securityAuthorized
        safeCouncilIsExecuted(_proposalId)
    {
        require(
            _oldOwner != address(0) &&
                _oldOwner != address(this) &&
                _newOwner != _oldOwner,
            "DLP118"
        );
        require(
            _newOwner != address(0) && _newOwner != address(this),
            "DLP119"
        );
        _safeCouncilUpdate(_proposalId, _ipfsUrl);
        delete isCouncil[_oldOwner];
        require(!isCouncil[_newOwner], "DLP117");
        isCouncil[_newOwner] = true;
        for (uint256 i = 0; i < councils.length; i++) {
            if (_oldOwner == councils[i]) {
                councils[i] = _newOwner;
                break;
            }
        }
        emit ChangeCouncil(_proposalId, _ipfsUrl, _oldOwner, _newOwner);
    }

    // Deletion of council members can only be implemented by the security committee
    ///@param _proposalId    Proposal ID
    ///@param _ipfsUrl   ipfs url
    ///@param _owner       Address to be removed
    function removeCouncil(
        uint256 _proposalId,
        string memory _ipfsUrl,
        address _owner
    )
        public
        nonReentrant
        securityAuthorized
        safeCouncilIsExecuted(_proposalId)
    {
        require(_owner != address(0) && _owner != address(this), "DLP119");
        _safeCouncilUpdate(_proposalId, _ipfsUrl);
        delete isCouncil[_owner];
        for (uint256 i = 0; i < councils.length; i++) {
            if (_owner == councils[i]) {
                delete councils[i];
                break;
            }
        }
        ownerCount--;
        _updateThreshold();
        emit RemovedCouncil(_proposalId, _ipfsUrl, _owner);
    }

    function getCouncils() public view returns (address[] memory _councils) {
        uint256 j = 0;
        for (uint256 i = 0; i < councils.length; i++) {
            if (councils[i] != address(0)) {
                _councils[j] = councils[i];
                j++;
            }
        }
        return _councils;
    }

    //Review the proposals passed by the Council
    ///@param _proposalId  Proposal ID
    ///@param _isPass      findings of audit
    function safeCouncilAudit(uint256 _proposalId, bool _isPass)
        public
        nonReentrant
        securityAuthorized
        proposalSafeCouncilIsExecute(_proposalId)
    {
        Proposal storage _proposal = proposals[_proposalId];
        if (_isPass) {
            _proposal.safeFlags[2] = true;
        } else {
            _proposal.safeFlags[0] = true;
        }
        emit SafeCouncilAudit(msg.sender, _proposalId, _isPass);
    }

    // Suspend task
    function safeCouncilIsPause(uint256 _proposalId)
        public
        nonReentrant
        securityAuthorized
        proposalSafeCouncilIsExecute(_proposalId)
    {
        Proposal storage _proposal = proposals[_proposalId];
        _proposal.safeFlags[1] = true;
        emit SafeCouncilPause(msg.sender, _proposalId);
    }

    // Recovery task
    function safeCouncilIsRest(uint256 _proposalId)
        public
        nonReentrant
        securityAuthorized
        proposalSafeCouncilIsRest(_proposalId)
    {
        Proposal storage _proposal = proposals[_proposalId];
        _proposal.safeFlags[1] = false;
        _proposal.deadline = _now256() + updateExpire;
        emit SafeCouncilRest(msg.sender, _proposalId);
    }

    /**
     *
     */
    function updateSecurityCouncil(address _newSecurityCouncil)
        public
        securityAuthorized
    {
        require(_newSecurityCouncil != address(0), "DLP120");
        securityCouncil = _newSecurityCouncil;
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
pragma solidity ^0.8.0;

/// @title Function for getting block timestamp.
/// @dev Base contract that is overridden for tests.
abstract contract Timestamp {
    /**
     * @dev Testing time-dependent functionality is difficult and the best way of
     *      doing it is to override time in helper test smart contracts.
     *
     * @return `block.timestamp` in mainnet, custom values in testnets (if overridden).
     */
    function _now256() internal view virtual returns (uint256) {
        // return current block timestamp
        return block.timestamp;
    }

    /**
     * @dev Empty reserved space in storage. The size of the __gap array is calculated so that
     *      the amount of storage used by a contract always adds up to the 50.
     *      See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}