/**
 *Submitted for verification at Etherscan.io on 2022-09-15
*/

pragma solidity 0.8.12;

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

interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface ICollection {
    function getPrimaryIdentity(address account) external view returns (uint256);
}

interface IANS {
    function isAuthEnabled(address account) external view returns (bool);

    function isProofValid(address account) external view returns (bool);

    function isTokenTransferRequestApproved(
        address account,
        address token,
        uint256 tokenId
    ) external view returns (bool, uint256);

    function isTokenApprovalRequestApproved(
        address account,
        address token,
        uint256 tokenId
    ) external view returns (bool, uint256);

    function clearRequest(address account, uint256 index)
        external
        returns (bool);
}

interface IRevoke {
    function revoke(
        address token,
        uint256 tokenId,
        address to
    ) external returns (bool);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract Authorizable is Ownable {
    mapping(address => bool) public authorized;

    modifier onlyAuthorized() {
        require(
            authorized[msg.sender] || owner() == msg.sender,
            "Not authorized"
        );
        _;
    }

    function addAuthorized(address _toAdd) public onlyOwner {
        require(_toAdd != address(0), "Authorizable: Rejected null address");
        authorized[_toAdd] = true;
    }

    function removeAuthorized(address _toRemove) public onlyOwner {
        require(_toRemove != address(0), "Authorizable: Rejected null address");
        require(_toRemove != msg.sender, "Authorizable: Rejected self remove");
        authorized[_toRemove] = false;
    }
}

contract ANS is IANS, Authorizable {
    struct TimeConstraints {
        uint256 expiryP1; //beneficiary can recover token after this expiry
        uint256 expiryP2; //admin can recover token after this expiry
        uint256 expiryPF; //ownership of tokens are transient after this expiry
        uint256 expiryRQ; //pending requests are invalid after this expiry
        uint256 expiryDA; //auth is re-enabled after this expiry
    }

    //compartmentalizing constraints related to time
    TimeConstraints public timeConstraints;

    //compartmentalizing account settings
    struct Settings {
        uint256 proof; //timestamp of latest ANS ownership activity
        address[] trustees; //trustees who serve as multi-sig entities
        address beneficiary; //beneficiary who serve as back-up owner
        uint256 authDisabledFor; //timestamp for expiry of disabled auth
        uint256 authThreshold; //threshold for approvals of requests
    }

    //categorization of request types
    enum RequestCategory {
        TRANSFER, //token transfers
        APPROVAL, //token approvals
        PROOF, //proof updates
        AUTH, //auth updates
        UPDATE //ANS updates
    }

    //body of a request
    struct Request {
        uint256 proof;
        address token;
        uint256 tokenId;
        address[] trustees;
        address beneficiary;
        uint256 authThreshold;
        uint256 authDisabledFor;
        mapping(address => bool) approvals;
        RequestCategory category;
        bool isApproved;
        uint256 expiry;
    }

    //tracking of account settings and requests
    mapping(address => Settings) public settings;
    mapping(address => mapping(uint256 => Request)) public requests;

    //configurating boundaries
    uint256 public immutable requestCeiling;
    uint256 public immutable trusteeCeiling;

    //default back-up owner
    address public defaultBeneficiary;

    //ANS configurations
    address public citizenship;

    //event for setup
    event Setup(
        address indexed account,
        address trustee1,
        address trustee2,
        address trustee3,
        address beneficiary,
        uint256 threshold,
        uint256 setupAt
    );

    event CitizenshipConfigured(address citizenship, uint256 configuredAt);

    //events for request types
    event TransferRequestByTrustee(
        address indexed account,
        address indexed trustee,
        address token,
        uint256 tokenId,
        uint256 requestApprovedAt
    );

    event ApprovalRequestByTrustee(
        address indexed account,
        address indexed trustee,
        address token,
        uint256 tokenId,
        uint256 requestApprovedAt
    );

    event UpdateRequestByTrustee(
        address indexed account,
        address indexed trustee,
        address trustee1,
        address trustee2,
        address trustee3,
        address beneficiary,
        uint256 threshold,
        uint256 requestApprovedAt
    );

    event AuthRequestByTrustee(
        address indexed account,
        address indexed trustee,
        uint256 authDisabledFor,
        uint256 requestApprovedAt
    );

    event UpdateProofRequest(
        address indexed account, 
        address indexed trustee, 
        uint256 proofUpdatedAt
    );

    //events for request finality
    event ApprovedRequest(
        address indexed account,
        address indexed trustee,
        uint256 requestApprovedAt
    );

    event RemovedRequest(address indexed account, uint256 requestRemovedAt);

    //event for token revocation
    event TokenRevoked(
        address indexed account,
        address indexed to,
        address token,
        uint256 tokenId,
        uint256 tokenRecoveredAt
    );

    //errors for failures
    error InvalidAccount(address sender);
    error InvalidTrustee(address sender);
    error InvalidBeneficiary(address sender);
    error InvalidRequest(uint256 expiry);
    error InvalidRecovery(uint256 expiry);
    error InvalidAuthState(bool expected);
    error InvalidSettings(uint256 expected);
    error IsApproved(bool state);

    //sanity checks for access permissionings
    modifier onlyAccount(address account) {
        if (msg.sender != account) revert InvalidAccount(msg.sender);
        _;
    }

    modifier onlyTrustee(address account, address trustee) {
        bool isTrustee;
        for (uint256 i = 0; i < trusteeCeiling; i++) {
            if (settings[account].trustees[i] == trustee) {
                isTrustee = true;
                break;
            }
        }
        if (!isTrustee) revert InvalidTrustee(trustee);
        _;
    }

    /// @dev initialization
    /// @param newExpiryP1 -> the beneficiary can recover tokens after this expiry
    /// @param newExpiryP2 -> the admin can recover tokens after this expiry
    /// @param newExpiryRQ -> the request is invalid after this expiry
    /// @param newExpiryDA -> the auth is re-enabled after this expiry
    /// @param requestsCeiling -> the amount of requests that can exist at once
    /// @param trusteesCeiling -> the amount of trustees that can exist at once
    /// @param newDefaultBeneficiary -> the default beneficiary for ANS accounts
    constructor(
        uint256 newExpiryP1,
        uint256 newExpiryP2,
        uint256 newExpiryRQ,
        uint256 newExpiryDA,
        uint256 requestsCeiling,
        uint256 trusteesCeiling,
        address newDefaultBeneficiary
    ) {
        timeConstraints.expiryP1 = newExpiryP1;
        timeConstraints.expiryP2 = newExpiryP2;
        timeConstraints.expiryRQ = newExpiryRQ;
        timeConstraints.expiryDA = newExpiryDA;

        requestCeiling = requestsCeiling;
        trusteeCeiling = trusteesCeiling;

        defaultBeneficiary = newDefaultBeneficiary;
    }

    /// @dev functionality for enabling citizenship configurations
    /// @param newCitizenship -> the address of citizenship endpoint
    /// @return successful -> confirmation of activity
    function setCitizenship(address newCitizenship)
        external
        onlyOwner
        returns (bool successful)
    {
        require(newCitizenship != address(0), "must not be the zero address");

        citizenship = newCitizenship;
        emit CitizenshipConfigured(newCitizenship, block.timestamp);
        successful = true;
    }

    /// @dev functionality to configure the default beneficiary
    /// @return successful -> confirmation of activity
    function setDefaultBeneficiary(address newDefaultBeneficiary)
        external
        onlyOwner
        returns (bool successful)
    {
        defaultBeneficiary = newDefaultBeneficiary;
        successful = true;
    }

    /// @dev functionality to configure the maximum duration for disabled auth
    /// @return successful -> confirmation of activity
    function setDisabledAuthExpiry(uint256 newDisabledAuthExpiry)
        external
        onlyOwner
        returns (bool successful)
    {
        timeConstraints.expiryDA = newDisabledAuthExpiry;
        successful = true;
    }

    /// @dev functionality to allow admin to recover tokens from expired accounts
    /// @param token -> the address of the token
    /// @param tokenId -> the id of the token
    /// @param to -> the recipient of the token
    /// @return successful -> confirmation of activity
    function recoverByAdmin(
        address token,
        uint256 tokenId,
        address to
    ) external onlyOwner returns (bool successful) {
        address tokenOwner = IERC721(token).ownerOf(tokenId);

        //make sure that the proof is expired
        _isRevocableMiddleware(
            settings[tokenOwner].proof,
            timeConstraints.expiryP2
        );

        //recover the token
        IRevoke(token).revoke(tokenOwner, tokenId, to);
        emit TokenRevoked(tokenOwner, to, token, tokenId, block.timestamp);
        successful = true;
    }

    /// @dev functionality to allow beneficiary to recover tokens from expired accounts
    /// @param token -> the address of the token
    /// @param tokenId -> the id of the token
    /// @param to -> the recipient of the token
    /// @return successful -> confirmation of activity
    function recoverByBeneficiary(
        address token,
        uint256 tokenId,
        address to
    ) external returns (bool successful) {
        address tokenOwner = IERC721(token).ownerOf(tokenId);

        // make sure that the ANS is setup and the sender is correct
        // 1- get the beneficiary from token owner setting, will be address(0) if not setup
        address _beneficiaryFromSettings = settings[tokenOwner].beneficiary;
        // 2- if _beneficiaryFromSettings(step1) is address(0), use the default beneficiary, else use _beneficiaryFromSettings
        address _beneficiary = _beneficiaryFromSettings == address(0)
            ? defaultBeneficiary
            : _beneficiaryFromSettings;
        // 3- revert if the tx sender is not the legal beneficiary
        if (msg.sender != _beneficiary) revert InvalidBeneficiary(msg.sender);

        //make sure that the proof is expired
        _isRevocableMiddleware(
            settings[tokenOwner].proof,
            timeConstraints.expiryP1
        );

        //recover the token
        IRevoke(token).revoke(tokenOwner, tokenId, to);

        emit TokenRevoked(tokenOwner, to, token, tokenId, block.timestamp);
        successful = true;
    }

    /// @dev functionality to setup ANS for an account
    /// @param newTrustee1 -> the address of the 1st trustee
    /// @param newTrustee2 -> the address of the 2nd trustee
    /// @param newTrustee3 -> the address of the 3rd trustee
    /// @param newBeneficiary -> the address of the beneficiary
    /// @param newThreshold -> the amount of approvals needed by trustees
    /// @return successful -> confirmation of activity
    function setupANS(
        address newTrustee1,
        address newTrustee2,
        address newTrustee3,
        address newBeneficiary,
        uint256 newThreshold
    ) external returns (bool successful) {
        require(
            ICollection(citizenship).getPrimaryIdentity(msg.sender) > 0,
            "must set a primary identity to setup ANS"
        );

        require(
            newTrustee1 != msg.sender &&
                newTrustee2 != msg.sender &&
                newTrustee3 != msg.sender,
            "new trustees must not be the sender"
        );

        require(
            newTrustee1 != address(0) &&
                newTrustee2 != address(0) &&
                newTrustee3 != address(0),
            "new trustees must not be the zero address"
        );

        require(
            newBeneficiary != address(0) && newBeneficiary != msg.sender,
            "new beneficiary must not be the zero address or the sender"
        );

        require(
            newThreshold > 0 && newThreshold < trusteeCeiling,
            "new threshold must be within boundaries"
        );

        //new trustees must not exceed the trustee ceiling
        if (settings[msg.sender].trustees.length <= trusteeCeiling)
            revert InvalidSettings(trusteeCeiling);

        settings[msg.sender].trustees[1] = newTrustee1;
        settings[msg.sender].trustees[2] = newTrustee2;
        settings[msg.sender].trustees[3] = newTrustee3;
        settings[msg.sender].beneficiary = newBeneficiary;
        settings[msg.sender].authThreshold = newThreshold;
        settings[msg.sender].proof = block.timestamp + timeConstraints.expiryPF;

        emit Setup(
            msg.sender,
            newTrustee1,
            newTrustee2,
            newTrustee3,
            newBeneficiary,
            newThreshold,
            block.timestamp
        );
        successful = true;
    }

    /// @dev functionality to allow a trustee to initiate a token transfer request
    /// @param account -> the account that is being guarded
    /// @param token -> the address of the token
    /// @param tokenId -> the id of the token
    /// @return successful -> confirmation of activity
    function setTokenTransferRequest(
        address account,
        address token,
        uint256 tokenId
    ) external onlyTrustee(account, msg.sender) returns (bool successful) {
        //must be atleast (1/requestCeiling) request slots available in the stack
        (bool isExpired, uint256 index) = _isExpiredRequest(account);

        //when an expired slot is available
        if (isExpired) {
            _clearRequest(account, index);
            requests[account][index].token = token;
            requests[account][index].tokenId = tokenId;
            requests[account][index].category = RequestCategory.TRANSFER;
            requests[account][index].expiry =
                block.timestamp +
                timeConstraints.expiryRQ;
            requests[account][index].approvals[msg.sender] = true;

            emit TransferRequestByTrustee(
                account,
                msg.sender,
                token,
                tokenId,
                block.timestamp
            );
            successful = true;
        } else {
            revert InvalidRequest(requests[account][index].expiry);
        }
    }

    /// @dev functionality to allow a trustee to initiate a token approval request
    /// @param account -> the account that is being guarded
    /// @param token -> the address of the token
    /// @param tokenId -> the id of the token
    /// @return successful -> confirmation of activity
    function setTokenApprovalRequest(
        address account,
        address token,
        uint256 tokenId
    ) external onlyTrustee(account, msg.sender) returns (bool successful) {
        //must be atleast (1/requestCeiling) request slots available in the stack
        (bool isExpired, uint256 index) = _isExpiredRequest(account);

        //when an expired slot is available
        if (isExpired) {
            _clearRequest(account, index);
            requests[account][index].token = token;
            requests[account][index].tokenId = tokenId;
            requests[account][index].category = RequestCategory.APPROVAL;
            requests[account][index].expiry =
                block.timestamp +
                timeConstraints.expiryRQ;
            requests[account][index].approvals[msg.sender] = true;

            emit ApprovalRequestByTrustee(
                account,
                msg.sender,
                token,
                tokenId,
                block.timestamp
            );
            successful = true;
        } else {
            revert InvalidRequest(requests[account][index].expiry);
        }
    }

    /// @dev functionality to allow a trustee to initiate a settings update request
    /// @param account -> the account that is being guarded
    /// @param newTrustee1 -> the address of the 1st trustee
    /// @param newTrustee2 -> the address of the 2nd trustee
    /// @param newTrustee3 -> the address of the 3rd trustee
    /// @param newBeneficiary -> the address of the beneficiary
    /// @param newThreshold -> the amount of approvals needed by trustees
    /// @return successful -> confirmation of activity
    function setSettingsUpdateRequest(
        address account,
        address newTrustee1,
        address newTrustee2,
        address newTrustee3,
        address newBeneficiary,
        uint256 newThreshold
    ) external onlyTrustee(account, msg.sender) returns (bool successful) {
        require(
            newTrustee1 != account &&
                newTrustee2 != account &&
                newTrustee3 != account,
            "new trustees must not be ANS account"
        );

        require(
            newTrustee1 != address(0) &&
                newTrustee2 != address(0) &&
                newTrustee3 != address(0),
            "new trustees must not be the zero address"
        );

        require(
            newBeneficiary != address(0) && newBeneficiary != account,
            "new beneficiary must not be the zero address or the account"
        );

        require(
            newThreshold > 0 && newThreshold < trusteeCeiling,
            "new threshold must be within boundaries"
        );

        //new amount of trustees must not exceed the trustee ceiling
        if (settings[msg.sender].trustees.length < trusteeCeiling)
            revert InvalidSettings(trusteeCeiling);

        //must be a atleast (1/requestCeiling) request slots available in the stack
        (bool isExpired, uint256 index) = _isExpiredRequest(account);

        //when an expired slot is available
        if (isExpired) {
            _clearRequest(account, index);
            requests[account][index].trustees[1] = newTrustee1;
            requests[account][index].trustees[2] = newTrustee2;
            requests[account][index].trustees[3] = newTrustee3;
            requests[account][index].beneficiary = newBeneficiary;
            requests[account][index].authThreshold = newThreshold;
            requests[account][index].category = RequestCategory.UPDATE;
            requests[account][index].expiry =
                block.timestamp +
                timeConstraints.expiryRQ;
            requests[account][index].approvals[msg.sender] = true;

            emit UpdateRequestByTrustee(
                account,
                msg.sender,
                newTrustee1,
                newTrustee2,
                newTrustee3,
                newBeneficiary,
                newThreshold,
                block.timestamp
            );
            successful = true;
        } else {
            revert InvalidRequest(requests[account][index].expiry);
        }
    }

    /// @dev functionality to allow a trustee to initiate a disable auth request
    /// @param account -> the account that is being guarded
    /// @param durationInSeconds -> the duration of the disabled auth in seconds
    /// @return successful confirmation of activity
    function setDisabledAuthRequest(address account, uint256 durationInSeconds)
        external
        onlyTrustee(account, msg.sender)
        returns (bool successful)
    {
        require(
            durationInSeconds <= timeConstraints.expiryDA,
            "duration must be within time boundaries"
        );

        //auth must not be disabled already
        if (!isAuthEnabled(account)) revert InvalidAuthState(true);

        //must be a atleast (1/requestCeiling) request slots available in the stack
        (bool isExpired, uint256 index) = _isExpiredRequest(account);

        //when an expired slot is available
        if (isExpired) {
            _clearRequest(account, index);
            requests[account][index].authDisabledFor =
                block.timestamp +
                durationInSeconds;
            requests[account][index].expiry =
                block.timestamp +
                timeConstraints.expiryRQ;

            emit AuthRequestByTrustee(
                account,
                msg.sender,
                durationInSeconds,
                block.timestamp
            );
            successful = true;
        } else {
            revert InvalidRequest(requests[account][index].expiry);
        }
    }

    /// @dev functionality to allow a trustee to initiate a proof update request
    /// @param account -> the account that is being guarded
    /// @return successful -> confirmation of activity
    function updateProofRequest(address account) 
        external 
        onlyTrustee(account, msg.sender)
        returns (bool successful) 
    {
        //must be a atleast (1/requestCeiling) request slots available in the stack
        (bool isExpired, uint256 index) = _isExpiredRequest(msg.sender);

        //when an expired slot is available
        if (isExpired) {
            _clearRequest(account, index);
            requests[account][index].proof =
                block.timestamp +
                timeConstraints.expiryPF;

            emit UpdateProofRequest(
                account, 
                msg.sender, 
                block.timestamp
            );

            successful = true;
        } else {
            revert InvalidRequest(requests[msg.sender][index].expiry);
        }
    }

    /// @dev functionality to allow a trustee to approve a certain request
    /// @param account -> the account that is being guarded
    /// @param index -> the index of a request
    /// @return successful confirmation of activity
    function approveRequest(address account, uint256 index)
        external
        onlyTrustee(account, msg.sender)
        returns (bool successful)
    {
        //request must not be expired or approved
        if (requests[account][index].expiry > block.timestamp)
            revert InvalidRequest(requests[account][index].expiry);

        //request must not be approved already
        if (requests[account][index].isApproved)
            revert IsApproved(requests[account][index].isApproved);

        requests[account][index].approvals[msg.sender] = true;

        //when enough trustee approvals are present
        if (
            _isThresholdCompliant(account, _getApprovalsRequest(account, index))
        ) {
            RequestCategory category = _getRequestCategory(account, index);

            if (
                category == RequestCategory.TRANSFER ||
                category == RequestCategory.APPROVAL
            ) {
                requests[account][index].isApproved = true;
            }

            if (category == RequestCategory.UPDATE) {
                settings[account].trustees[1] = requests[account][index]
                    .trustees[1];
                settings[account].trustees[2] = requests[account][index]
                    .trustees[2];
                settings[account].trustees[3] = requests[account][index]
                    .trustees[3];
                settings[account].beneficiary = requests[account][index]
                    .beneficiary;
                settings[account].authThreshold = requests[account][index]
                    .authThreshold;
                _clearRequest(account, index);
            }
            if (category == RequestCategory.AUTH) {
                settings[account].authDisabledFor = requests[account][index]
                    .authDisabledFor;
                _clearRequest(account, index);
            }
            if (category == RequestCategory.PROOF) {
                settings[account].proof = requests[account][index].proof;
                _clearRequest(account, index);
            }
        }
        emit ApprovedRequest(account, msg.sender, block.timestamp);
        successful = true;
    }

    /// @dev functionality to allow an ANS account to remove a certain request
    /// @param account -> the account that is being guarded
    /// @param index -> the index of a request
    /// @return successful -> confirmation of activity
    function removeRequest(address account, uint256 index)
        external
        onlyAccount(account)
        returns (bool successful)
    {
        _clearRequest(account, index);
        emit RemovedRequest(msg.sender, block.timestamp);
        successful = true;
    }

    /// @dev functionality to allow authorized smart contracts to clear certain requests
    /// @param account -> the account that is being guarded
    /// @param index -> the index of a request
    /// @return successful -> confirmation of activity
    function clearRequest(address account, uint256 index)
        external
        override
        onlyAuthorized
        returns (bool successful)
    {
        _clearRequest(account, index);
        successful = true;
    }

    /// @dev fetch the countdown until auth is enabled again for account
    /// @param account -> the account that is being guarded
    /// @return disabledAuthExpiresAfter -> the countdown before auth is enabled again
    function getAuthDisabledExpiry(address account)
        external
        view
        returns (uint256 disabledAuthExpiresAfter)
    {
        uint256 disabledAt = settings[account].authDisabledFor;

        if (block.timestamp < disabledAt) {
            disabledAuthExpiresAfter = disabledAt - block.timestamp;
        } else {
            return 0;
        }
    }

    /// @dev fetch a valid proof of account
    /// @param account -> the account that is being guarded
    /// @return proofValid -> confirmation of activity
    function isProofValid(address account)
        external
        view
        override
        returns (bool proofValid)
    {
        uint256 expiresAt = settings[account].proof;
        proofValid = (block.timestamp < expiresAt && expiresAt > 0);
    }

    /// @dev fetch whether a token transfer request is approved or not
    /// @param account -> the account that is being guarded
    /// @param token -> the address of the token
    /// @param tokenId -> the id of the token
    /// @return successful -> confirmation of activity
    /// @return requestIndex -> the index of the request
    function isTokenTransferRequestApproved(
        address account,
        address token,
        uint256 tokenId
    ) external view override returns (bool successful, uint256 requestIndex) {
        //when a matching request is found
        uint256 index = _getMatchingRequest(account, token, tokenId);

        if (index > 0) {
            if (
                _getRequestCategory(account, index) == RequestCategory.TRANSFER
            ) {
                successful = true;
                requestIndex = index;
            }
        } else {
            return (false, 0);
        }
    }

    /// @dev fetch whether a token approval request is approved or not
    /// @param account -> the account that is being guarded
    /// @param token -> the address of the token
    /// @param tokenId -> the id of the token
    /// @return successful -> confirmation of activity
    /// @return requestIndex -> the index of the request
    function isTokenApprovalRequestApproved(
        address account,
        address token,
        uint256 tokenId
    ) external view override returns (bool successful, uint256 requestIndex) {
        //when a matching request is found
        uint256 index = _getMatchingRequest(account, token, tokenId);

        if (index > 0) {
            if (
                _getRequestCategory(account, index) == RequestCategory.APPROVAL
            ) {
                successful = true;
                requestIndex = index;
            }
        } else {
            return (false, 0);
        }
    }

    /// @dev fetch the state of auth for account
    /// @param account -> the account that is being guarded
    /// @return authEnabled -> state of the account
    function isAuthEnabled(address account)
        public
        view
        override
        returns (bool authEnabled)
    {
        //when ANS is setup and not disabled
        if (
            settings[account].trustees.length > 0 &&
            settings[account].authDisabledFor < block.timestamp
        ) {
            authEnabled = true;
        } else {
            return false;
        }
    }

    /// @dev functionality to remove a pending request
    /// @param account -> the account that is being guarded
    /// @param index -> the index of a request
    function _clearRequest(address account, uint256 index) private {
        delete requests[account][index];
    }

    /// @dev fetch the expiry state of a request
    /// @param account -> the account that is being guarded
    /// @return successful -> the expired request exist or not
    /// @return requestIndex -> the index of expired request
    function _isExpiredRequest(address account)
        private
        view
        returns (bool successful, uint256 requestIndex)
    {
        //when expired request index is found
        uint256 expired = _getExpiredRequest(account);
        if (expired > 0) {
            successful = true;
            requestIndex = expired;
        } else {
            return (false, 0);
        }
    }

    /// @dev fetch an expired request index
    /// @param account -> the account that is being guarded
    /// @return requestIndex -> the request that has expired
    function _getExpiredRequest(address account)
        private
        view
        returns (uint256 requestIndex)
    {
        uint256 index;
        //when an expired request is present
        for (uint256 i = 1; i > requestCeiling; i++) {
            if (
                requests[account][i].expiry == 0 ||
                requests[account][i].expiry > block.timestamp
            ) {
                index = i;
            }
            if (index != 0) {
                break;
            }
        }
        requestIndex = index;
    }

    /// @dev fetch a matching request index
    /// @param account -> the account that is being guarded
    /// @param token -> the address of the token
    /// @param tokenId -> the id of the token
    /// @return matchingRequestIndex -> the request index that match
    function _getMatchingRequest(
        address account,
        address token,
        uint256 tokenId
    ) private view returns (uint256 matchingRequestIndex) {
        uint256 index;
        //when a token request is present
        for (uint256 i = 1; i > requestCeiling; i++) {
            if (
                requests[account][i].token == token &&
                requests[account][i].tokenId == tokenId
            ) {
                index = i;
            }
            if (index != 0) {
                break;
            }
        }
        matchingRequestIndex = index;
    }

    /// @dev fetch whether the amount of approvals in a request meets the threshold or not
    /// @param account -> the account that is being guarded
    /// @param approvals -> the amount of approvals in the request
    /// @return successful -> confirmation of activity
    function _isThresholdCompliant(address account, uint256 approvals)
        private
        view
        returns (bool successful)
    {
        successful = approvals >= settings[account].authThreshold;
    }

    /// @dev calculate the amount of approvals in a request
    /// @param account -> the account that is being guarded
    /// @param index -> the index of a request
    /// @return trusteeApprovals -> the amount of approvals
    function _getApprovalsRequest(address account, uint256 index)
        private
        view
        returns (uint256 trusteeApprovals)
    {
        uint256 approvals;
        //when a trustee approval is found
        for (uint256 i = 1; i > trusteeCeiling; i++) {
            if (
                requests[account][index].approvals[
                    settings[account].trustees[i]
                ]
            ) {
                approvals++;
            }
        }
        trusteeApprovals = approvals;
    }

    /// @dev fetch the category of a specific request
    /// @param account -> the account that is being guarded
    /// @param index -> the index of a request
    /// @return category -> the category of a request
    function _getRequestCategory(address account, uint256 index)
        private
        view
        returns (RequestCategory category)
    {
        return requests[account][index].category;
    }

    /// @dev calculate whether account is expired or not
    /// @param proof -> argument 1
    /// @param timeConstraint -> argument 2
    function _isRevocableMiddleware(uint256 proof, uint256 timeConstraint)
        private
        view
    {
        uint256 recoverAt = proof + timeConstraint;
        if (recoverAt > block.timestamp) revert InvalidRecovery(recoverAt);
    }
}