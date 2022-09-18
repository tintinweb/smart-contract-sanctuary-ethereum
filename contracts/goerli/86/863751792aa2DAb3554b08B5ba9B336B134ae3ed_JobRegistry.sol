// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ITalentLayerID} from "./interfaces/ITalentLayerID.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title JobRegistry Contract
 * @author TalentLayer Team @ ETHCC22 Hackathon
 */
contract JobRegistry is AccessControl {
    // =========================== Enum ==============================

    /// @notice Enum job status
    enum Status {
        Filled,
        Confirmed,
        Finished,
        Rejected,
        Opened
    }

    /// @notice Enum job status
    enum ProposalStatus {
        Pending,
        Validated,
        Rejected
    }

    // =========================== Struct ==============================

    /// @notice Job information struct
    /// @param status the current status of a job
    /// @param employerId the talentLayerId of the employer
    /// @param employeeId the talentLayerId of the employee
    /// @param initiatorId the talentLayerId of the user who initialized the job
    /// @param jobDataUri token Id to IPFS URI mapping
    /// @param proposals all proposals for this job
    /// @param countProposals the total number of proposal for this job
    /// @param transactionId the escrow transaction ID linked to the job
    struct Job {
        Status status;
        uint256 employerId;
        uint256 employeeId;
        uint256 initiatorId;
        string jobDataUri;
        uint256 countProposals;
        uint256 transactionId;
    }

    /// @notice Proposal information struct
    /// @param status the current status of a job
    /// @param employeeId the talentLayerId of the employee
    /// @param rateToken the token choose for the payment
    /// @param rateAmount the amount of token choosed
    /// @param proposalDataUri token Id to IPFS URI mapping
    struct Proposal {
        ProposalStatus status;
        uint256 employeeId;
        address rateToken;
        uint256 rateAmount;
        string proposalDataUri;
    }

    // =========================== Events ==============================

    /// @notice Emitted after a new job is created
    /// @param id The job ID (incremental)
    /// @param employerId the talentLayerId of the employer
    /// @param employeeId the talentLayerId of the employee
    /// @param initiatorId the talentLayerId of the user who initialized the job
    /// @param jobDataUri token Id to IPFS URI mapping
    /// @param status job status
    event JobCreated(
        uint256 id,
        uint256 employerId,
        uint256 employeeId,
        uint256 initiatorId,
        string jobDataUri,
        Status status
    );

    /// @notice Emitted after a new job is created
    /// @param id The job ID
    /// @param employeeId the talentLayerId of the employee
    /// @param status job status
    event JobEmployeeAssigned(uint256 id, uint256 employeeId, Status status);

    /// @notice Emitted after a job is confirmed
    /// @param id The job ID
    /// @param employerId the talentLayerId of the employer
    /// @param employeeId the talentLayerId of the employee
    /// @param jobDataUri token Id to IPFS URI mapping
    event JobConfirmed(
        uint256 id,
        uint256 employerId,
        uint256 employeeId,
        string jobDataUri
    );

    /// @notice Emitted after a job is rejected
    /// @param id The job ID
    /// @param employerId the talentLayerId of the employer
    /// @param employeeId the talentLayerId of the employee
    /// @param jobDataUri token Id to IPFS URI mapping
    event JobRejected(
        uint256 id,
        uint256 employerId,
        uint256 employeeId,
        string jobDataUri
    );

    /// @notice Emitted after a job is finished
    /// @param id The job ID
    /// @param employerId the talentLayerId of the employer
    /// @param employeeId the talentLayerId of the employee
    /// @param jobDataUri token Id to IPFS URI mapping
    event JobFinished(
        uint256 id,
        uint256 employerId,
        uint256 employeeId,
        string jobDataUri
    );

    /// @notice Emitted after a new proposal is created
    /// @param jobId The job id
    /// @param employeeId The talentLayerId of the employee who made the proposal
    /// @param proposalDataUri token Id to IPFS URI mapping
    /// @param status proposal status
    /// @param rateToken the token choose for the payment
    /// @param rateAmount the amount of token choosed
    event ProposalCreated(
        uint256 jobId,
        uint256 employeeId,
        string proposalDataUri,
        ProposalStatus status,
        address rateToken,
        uint256 rateAmount
    );

    /// @notice Emitted after an existing proposal has been update
    /// @param jobId The job id
    /// @param employeeId The talentLayerId of the employee who made the proposal
    /// @param proposalDataUri token Id to IPFS URI mapping
    /// @param rateToken the token choose for the payment
    /// @param rateAmount the amount of token choosed
    event ProposalUpdated(
        uint256 jobId,
        uint256 employeeId,
        string proposalDataUri,
        address rateToken,
        uint256 rateAmount
    );

    /// @notice Emitted after a proposal is validated
    /// @param jobId The job ID
    /// @param employeeId the talentLayerId of the employee
    event ProposalValidated(uint256 jobId, uint256 employeeId);

    /// @notice Emitted after a proposal is rejected
    /// @param jobId The job ID
    /// @param employeeId the talentLayerId of the employee
    event ProposalRejected(uint256 jobId, uint256 employeeId);

    /// @notice Emitted after a job is finished
    /// @param id The job ID
    /// @param proposalId the proposal ID
    /// @param employeeId the talentLayerId of the employee
    /// @param transactionId the escrow transaction ID
    event JobProposalConfirmedWithDeposit(
        uint256 id,
        uint256 proposalId,
        uint256 employeeId,
        uint256 transactionId
    );

    /// @notice incremental job Id
    uint256 public nextJobId = 1;

    /// @notice TalentLayerId address
    ITalentLayerID private tlId;

    /// @notice jobs mappings index by ID
    mapping(uint256 => Job) public jobs;

    /// @notice proposals mappings index by job ID and employee TID
    mapping(uint256 => mapping (uint256 => Proposal)) public proposals;

    // @notice
    bytes32 public constant ESCROW_ROLE = keccak256("ESCROW_ROLE");

    /**
     * @param _talentLayerIdAddress TalentLayerId address
     */
    constructor(address _talentLayerIdAddress) {
        tlId = ITalentLayerID(_talentLayerIdAddress);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // =========================== View functions ==============================

    /**
     * @notice Return the whole job data information
     * @param _jobId Job identifier
     */
    function getJob(uint256 _jobId) external view returns (Job memory) {
        require(_jobId < nextJobId, "This job does'nt exist");
        return jobs[_jobId];
    }

    function getProposal(uint256 _jobId, uint256 _proposalId) external view returns (Proposal memory) {
        return proposals[_jobId][_proposalId];
    }

    // =========================== User functions ==============================

    /**
     * @notice Allows an employer to initiate a new Job with an employee
     * @param _employeeId Handle for the user
     * @param _jobDataUri token Id to IPFS URI mapping
     */
    function createJobFromEmployer(
        uint256 _employeeId,
        string calldata _jobDataUri
    ) public returns (uint256) {
        require(_employeeId > 0, "Employee 0 is not a valid TalentLayerId");
        uint256 senderId = tlId.walletOfOwner(msg.sender);
        return
            _createJob(
                Status.Filled,
                senderId,
                senderId,
                _employeeId,
                _jobDataUri
            );
    }

    /**
     * @notice Allows an employee to initiate a new Job with an employer
     * @param _employerId Handle for the user
     * @param _jobDataUri token Id to IPFS URI mapping
     */
    function createJobFromEmployee(
        uint256 _employerId,
        string calldata _jobDataUri
    ) public returns (uint256) {
        require(_employerId > 0, "Employer 0 is not a valid TalentLayerId");
        uint256 senderId = tlId.walletOfOwner(msg.sender);
        return
            _createJob(
                Status.Filled,
                senderId,
                _employerId,
                senderId,
                _jobDataUri
            );
    }

    /**
     * @notice Allows an employer to initiate an open job
     * @param _jobDataUri token Id to IPFS URI mapping
     */
    function createOpenJobFromEmployer(string calldata _jobDataUri)
        public
        returns (uint256)
    {
        uint256 senderId = tlId.walletOfOwner(msg.sender);
        return _createJob(Status.Opened, senderId, senderId, 0, _jobDataUri);
    }

    /**
     * @notice Allows an employee to propose his service for a job
     * @param _jobId The job linked to the new proposal
     * @param _rateToken the token choose for the payment
     * @param _rateAmount the amount of token choosed
     * @param _proposalDataUri token Id to IPFS URI mapping
     */
    function createProposal(
        uint256 _jobId,
        address _rateToken,
        uint256 _rateAmount,
        string calldata _proposalDataUri
    ) public {
        uint256 senderId = tlId.walletOfOwner(msg.sender);
        require(senderId > 0, "You sould have a TalentLayerId");

        Job storage job = jobs[_jobId];
        require(job.status == Status.Opened, "Job is not opened");
        require(
            proposals[_jobId][senderId].employeeId != senderId,
            "You already created a proposal for this job"
        );
        require(job.countProposals < 40, "Max proposals count reached");
        require(
            job.employerId != senderId,
            "You couldn't create proposal for your own job"
        );
        require(
            bytes(_proposalDataUri).length > 0,
            "Should provide a valid IPFS URI"
        );

        job.countProposals++;
        proposals[_jobId][senderId] = Proposal({
            status: ProposalStatus.Pending,
            employeeId: senderId,
            rateToken: _rateToken,
            rateAmount: _rateAmount,
            proposalDataUri: _proposalDataUri
        });

        emit ProposalCreated(
            _jobId,
            senderId,
            _proposalDataUri,
            ProposalStatus.Pending,
            _rateToken,
            _rateAmount
        );
    }

    /**
     * @notice Allows an employee to update his own proposal for a given job
     * @param _jobId The job linked to the new proposal
     * @param _rateToken the token choose for the payment
     * @param _rateAmount the amount of token choosed
     * @param _proposalDataUri token Id to IPFS URI mapping
     */
    function updateProposal(
        uint256 _jobId,
        address _rateToken,
        uint256 _rateAmount,
        string calldata _proposalDataUri
    ) public {
        uint256 senderId = tlId.walletOfOwner(msg.sender);
        require(senderId > 0, "You sould have a TalentLayerId");

        Job storage job = jobs[_jobId];
        Proposal storage proposal = proposals[_jobId][senderId];
        require(job.status == Status.Opened, "Job is not opened");
        require(
            proposal.employeeId == senderId,
            "This proposal doesn't exist yet"
        );
        require(
            bytes(_proposalDataUri).length > 0,
            "Should provide a valid IPFS URI"
        );
        require(
            proposal.status != ProposalStatus.Validated,
            "This proposal is already updated"
        );

        proposal.rateToken = _rateToken;
        proposal.rateAmount = _rateAmount;
        proposal.proposalDataUri = _proposalDataUri;

        emit ProposalUpdated(
            _jobId,
            senderId,
            _proposalDataUri,
            _rateToken,
            _rateAmount
        );
    }

    /**
     * @notice Allows the employer to validate a proposal
     * @param _jobId Job identifier
     * @param _proposalId Proposal identifier
     */
    function validateProposal(uint256 _jobId, uint256 _proposalId) public {
        uint256 senderId = tlId.walletOfOwner(msg.sender);
        require(senderId > 0, "You sould have a TalentLayerId");

        Job storage job = jobs[_jobId];
        Proposal storage proposal = proposals[_jobId][_proposalId];

        require(
            proposal.status != ProposalStatus.Validated,
            "Proposal has already been validated"
        );
        require(senderId == job.employerId, "You're not the employer");

        proposal.status = ProposalStatus.Validated;

        emit ProposalValidated(_jobId, senderId);
    }

    /**
     * @notice Allows the employer to reject a proposal
     * @param _jobId Job identifier
     * @param _proposalId Proposal identifier
     */
    function rejectProposal(uint256 _jobId, uint256 _proposalId) public {
        uint256 senderId = tlId.walletOfOwner(msg.sender);
        require(senderId > 0, "You sould have a TalentLayerId");

        Job storage job = jobs[_jobId];
        Proposal storage proposal = proposals[_jobId][_proposalId];

        require(
            proposal.status != ProposalStatus.Validated,
            "Proposal has already been validated"
        );
        require(senderId == job.employerId, "You're not the employer");

        proposal.status = ProposalStatus.Rejected;

        emit ProposalRejected(_jobId, senderId);
    }

    /**
     * @notice Allows the user who didn't initiate the job to confirm it. They now consent both to be reviewed each other at the end of job.
     * @param _jobId Job identifier
     */
    function confirmJob(uint256 _jobId) public {
        Job storage job = jobs[_jobId];
        uint256 senderId = tlId.walletOfOwner(msg.sender);

        require(job.status == Status.Filled, "Job has already been confirmed");
        require(
            senderId == job.employerId || senderId == job.employeeId,
            "You're not an actor of this job"
        );
        require(
            senderId != job.initiatorId,
            "Only the user who didn't initate the job can confirm it"
        );

        job.status = Status.Confirmed;

        emit JobConfirmed(
            _jobId,
            job.employerId,
            job.employeeId,
            job.jobDataUri
        );
    }

    /**
     * @notice Allow the escrow contract to upgrade the Job state after a deposit has been done
     * @param _jobId Job identifier
     * @param _proposalId The choosed proposal id for this job
     * @param _transactionId The escrow transaction Id
     */
    function afterDeposit(uint256 _jobId, uint256 _proposalId, uint256 _transactionId) external onlyRole(ESCROW_ROLE) {
        Job storage job = jobs[_jobId];
        Proposal storage proposal = proposals[_jobId][_proposalId];
         
        job.status = Status.Confirmed;
        job.employeeId = proposal.employeeId;
        job.transactionId = _transactionId;
        proposal.status = ProposalStatus.Validated;

        emit JobProposalConfirmedWithDeposit(
            _jobId,
            _proposalId,
            job.employeeId,
            job.transactionId
        );
    }

    /**
     * @notice Allow the escrow contract to upgrade the Job state after the full payment has been received by the employee
     * @param _jobId Job identifier
     */
    function afterFullPayment(uint256 _jobId) external onlyRole(ESCROW_ROLE) {
        Job storage job = jobs[_jobId];
        job.status = Status.Finished;

        emit JobFinished(
            _jobId,
            job.employerId,
            job.employeeId,
            job.jobDataUri
        );
    }

    /**
     * @notice Allows the user who didn't initiate the job to reject it
     * @param _jobId Job identifier
     */
    function rejectJob(uint256 _jobId) public {
        Job storage job = jobs[_jobId];
        uint256 senderId = tlId.walletOfOwner(msg.sender);
        require(
            senderId == job.employerId || senderId == job.employeeId,
            "You're not an actor of this job"
        );
        require(
            job.status == Status.Filled || job.status == Status.Opened,
            "You can't reject this job"
        );
        job.status = Status.Rejected;

        emit JobRejected(
            _jobId,
            job.employerId,
            job.employeeId,
            job.jobDataUri
        );
    }

    /**
     * @notice Allows any part of a job to update his state to finished
     * @param _jobId Job identifier
     */
    function finishJob(uint256 _jobId) public {
        Job storage job = jobs[_jobId];
        uint256 senderId = tlId.walletOfOwner(msg.sender);
        require(
            senderId == job.employerId || senderId == job.employeeId,
            "You're not an actor of this job"
        );
        require(job.status == Status.Confirmed, "You can't finish this job");
        job.status = Status.Finished;

        emit JobFinished(
            _jobId,
            job.employerId,
            job.employeeId,
            job.jobDataUri
        );
    }

    /**
     * @notice Allows the employer to assign an employee to the job
     * @param _jobId Job identifier
     * @param _employeeId Handle for the user
     */
    function assignEmployeeToJob(uint256 _jobId, uint256 _employeeId) public {
        Job storage job = jobs[_jobId];
        uint256 senderId = tlId.walletOfOwner(msg.sender);

        require(
            job.status == Status.Opened || job.status == Status.Rejected,
            "Job has to be Opened or Rejected"
        );

        require(
            senderId == job.employerId,
            "You're not an employer of this job"
        );

        require(
            _employeeId != job.employerId,
            "Employee and employer can't be the same"
        );

        job.employeeId = _employeeId;
        job.status = Status.Filled;

        emit JobEmployeeAssigned(_jobId, _employeeId, job.status);
    }

    // =========================== Private functions ==============================

    /**
     * @notice Update handle address mapping and emit event after mint.
     * @param _senderId the talentLayerId of the msg.sender address
     * @param _employerId the talentLayerId of the employer
     * @param _employeeId the talentLayerId of the employee
     * @param _jobDataUri token Id to IPFS URI mapping
     */
    function _createJob(
        Status _status,
        uint256 _senderId,
        uint256 _employerId,
        uint256 _employeeId,
        string calldata _jobDataUri
    ) private returns (uint256) {
        require(
            _employeeId != _employerId,
            "Employee and employer can't be the same"
        );
        require(_senderId > 0, "You sould have a TalentLayerId");
        require(
            bytes(_jobDataUri).length > 0,
            "Should provide a valid IPFS URI"
        );

        uint256 id = nextJobId;
        nextJobId++;

        Job storage job = jobs[id];
        job.status = _status;
        job.employerId = _employerId;
        job.employeeId = _employeeId;
        job.initiatorId = _senderId;
        job.jobDataUri = _jobDataUri;

        emit JobCreated(
            id,
            _employerId,
            _employeeId,
            _senderId,
            _jobDataUri,
            _status
        );

        return id;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ITalentLayerID {
    function numberMinted(address _user) external view returns (uint256);

    function isTokenPohRegistered(uint256 _tokenId)
        external
        view
        returns (bool);

    function walletOfOwner(address _owner) external view returns (uint256);

    function mint(string memory _handle) external;

    function mintWithPoh(string memory _handle) external;

    function activatePoh(uint256 _tokenId) external;

    function updateProfileData(uint256 _tokenId, string memory _newCid)
        external;

    function recoverAccount(
        address _oldAddress,
        uint256 _tokenId,
        uint256 _index,
        uint256 _recoveryKey,
        string calldata _handle,
        bytes32[] calldata _merkleProof
    ) external;

    function setBaseURI(string memory _newBaseURI) external;

    function updateRecoveryRoot(bytes32 _newRoot) external;

    function _afterMint(string memory _handle) external;

    function ownerOf(uint256 _tokenId) external view returns (address);

    event Mint(address indexed _user, uint256 _tokenId, string _handle);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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