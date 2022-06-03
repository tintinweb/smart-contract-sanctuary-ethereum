// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

/* ========== STRUCTS ========== */

/**
 * @notice Represents a team in FeeManager.
 * @member id unique ID of the team
 * @member owner owner of the team
 * @member valid is the team valid
 */
struct Team {
    string id;
    address owner;
    bool valid;
}

/**
 * @dev Represents a balance of token for a team.
 * @member balance Amount deposited for team.
 * @member claimableWithdrawals Amount that can be withdrawn in the current cycle, i.e., requested in previous cycle.
 * @member unclaimableWithdrawals Amount that will become available for withdrawal in next cycle, i.e., requested in current cycle.
 * @member lastSynced Fee withdrawal cycle when this entry was last synced.
 */
struct BalanceBookEntry {
    uint256 balance;
    uint256 claimableWithdrawals;
    uint256 unclaimableWithdrawals;
    uint256 lastSynced;
}

/**
 * @notice Balance report for a team and token.
 * @member balance Amount deposited for team.
 * @member claimableWithdrawals Amount that can be withdrawn by team.
 * @member unclaimableWithdrawals Amount that was requested to be withdrawn by team. Will become claimable after fee collection.
 * @member collectableBalance Amount that can be collected for due fees for team (balance - claimableWithdrawals).
 * @member requestableBalance Amount that can be requested to be withdrawn by team (balance - claimableWithdrawals - unclaimableWithdrawals).
 */
struct BalanceReport {
    uint256 balance;
    uint256 claimableWithdrawals;
    uint256 unclaimableWithdrawals;
    uint256 collectableBalance;
    uint256 requestableBalance;
}

/* ========== CONTRACTS ========== */

/**
 * @title Fee management contract.
 * @notice This contract manages all aspects of fee collection:
 * - creation and managing of teams
 * - deposition and withdrawal of fees
 * - collection of fees
 * @dev Contract is Ownable and Upgradeable, and it uses SafeERC20 for token operations.
 */
contract FeeManager is OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /* ========== EVENTS ========== */

    /**
     * @notice Event emitted when fee recipient is set.
     * @dev Emitted when `_setFeeRecipient` is called.
     * @param oldRecipient Address of old fee recipient.
     * @param newRecipient Address of new fee recipient.
     */
    event FeeRecipientSet(address indexed oldRecipient, address indexed newRecipient);

    /**
     * @notice Event emitted when new tokens are allowed for fee deposits.
     * @dev Emitted when `_allowTokens` is called.
     * @param tokens List of newly allowed tokens.
     */
    event TokensAllowed(IERC20Upgradeable[] tokens);

    /**
     * @notice Event emitted when current tokens are disallowed for fee deposits.
     * @dev Emitted when `disallowTokens` is called.
     * @param tokens List of newly disallowed tokens.
     */
    event TokensDisallowed(IERC20Upgradeable[] tokens);

    /**
     * @notice Event emitted when new addresses are allowed to collect fees.
     * @dev Emitted when `_addFeeCollectors` is called.
     * @param collectors List of newly allowed collectors.
     */
    event FeeCollectorsAdded(address[] collectors);

    /**
     * @notice Event emitted when current addresses are disallowed to collect fees.
     * @dev Emitted when `removeFeeCollectors` is called.
     * @param collectors List of newly disallowed collectors.
     */
    event FeeCollectorsRemoved(address[] collectors);

    /**
     * @notice Event emitted when new team is created.
     * @dev Emitted when `createTeam` is called.
     * @param indexedTeamId Hashed team ID.
     * @param teamId Team ID.
     */
    event TeamCreated(string indexed indexedTeamId, string teamId);

    /**
     * @notice Event emitted when team ownership is transfered.
     * @dev Emitted when `_transferTeamOwnership` is called.
     * @param teamId Hashed team ID.
     * @param previousOwner Address of previous team owner.
     * @param newOwner Address of new team owner.
     */
    event TeamOwnershipTransferred(
        string indexed teamId,
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @notice Event emitted when permissions for withdrawal for team are added.
     * @dev Emitted when `_addPermissionForWithdrawalForTeam` is called.
     * @param teamId Hashed team ID.
     * @param allowed List of addresses newly allowed to withdraw.
     */
    event WithdrawalPermissionForTeamAdded(string indexed teamId, address[] allowed);

    /**
     * @notice Event emitted when permissions for withdrawal for team are removed.
     * @dev Emitted when `removePermissionForWithdrawalForTeam` is called.
     * @param teamId Hashed team ID.
     * @param disallowed List of addresses disallowed to withdraw.
     */
    event WithdrawalPermissionForTeamRemoved(string indexed teamId, address[] disallowed);

    /**
     * @notice Event emitted when fee is deposited for team.
     * @dev Emitted when `depositFee` is called.
     * @param teamId Hashed team ID.
     * @param token Token deposited.
     * @param amount Amount deposited.
     */
    event FeeDeposited(
        string indexed teamId,
        IERC20Upgradeable indexed token,
        uint256 amount
    );

    /**
     * @notice Event emitted when fee is collected for team.
     * @dev Emitted when `collectFees` is called.
     * @param teamId Hashed team ID.
     * @param token Token collected.
     * @param amount Amount collected.
     */
    event FeeCollected(
        string indexed teamId,
        IERC20Upgradeable indexed token,
        uint256 amount
    );

    /**
     * @notice Event emitted when fee collection is completed.
     * @dev Emitted when `collectFees` is called.
     * @param feeCollectionCycle The new collection cycle started.
     */
    event FeeCollectionComplete(uint256 feeCollectionCycle);

    /**
     * @notice Event emitted when fee withdrawal is requested for team.
     * @dev Emitted when `requestFeeWithdrawal` is called.
     * @param teamId Hashed team ID.
     * @param token Token requested.
     * @param amount Amount requested.
     */
    event FeeWithdrawalRequested(
        string indexed teamId,
        IERC20Upgradeable indexed token,
        uint256 amount
    );

    /**
     * @notice Event emitted when fee withdrawal is claimed for team.
     * @dev Emitted when `claimFeeWithdrawal` is called.
     * @param teamId Hashed team ID.
     * @param token Token claimed.
     * @param amount Amount claimed.
     */
    event FeeWithdrawalClaimed(
        string indexed teamId,
        IERC20Upgradeable indexed token,
        uint256 amount
    );

    /* ========== STATE VARIABLES ========== */

    /// @notice Recipient of collected fees.
    address public feeRecipient;
    /**
     * @notice Current fee collection cycle.
     * @dev Used to keep track of withdrawal requests.
     */
    uint256 public feeCollectionCycle;

    /// @notice Tokens allowed to be used for fee deposits.
    mapping(IERC20Upgradeable => bool) public allowedTokens;
    /// @notice Addresses allowed to collect fees.
    mapping(address => bool) public feeCollectors;
    /// @notice Created teams.
    mapping(string => Team) public teams;
    /// @notice Who can withdraw fees for team.
    mapping(string => mapping(address => bool)) public withdrawalAllowList;
    /// @dev Balance for team-token.
    mapping(string => mapping(IERC20Upgradeable => BalanceBookEntry))
        private _balanceBook;

    /* ========== INITIALIZATION ========== */

    /**
     * @notice Sets initial state.
     * The address deploying the contract is automatically set as the owner.
     * @dev This replaces `constructor` (upgradeable contract).
     * Can only be called once.
     * Is called as part of deployment procedure.
     * Requirements:
     * - fee recipient should not be the zero address
     * @param _feeRecipient Recipient of collected fees.
     * @param _allowedTokens Tokens allowed to be used for fee deposits.
     */
    function initialize(
        address _feeRecipient,
        IERC20Upgradeable[] calldata _allowedTokens,
        address[] calldata _feeCollectors
    ) public initializer {
        // Call initializers for parent contracts.
        __Ownable_init();

        // Set initial state.
        _setFeeRecipient(_feeRecipient);
        _allowTokens(_allowedTokens);
        _addFeeCollectors(_feeCollectors);
    }

    /* ========== CONTRACT MANAGEMENT FUNCTIONS ========== */

    /**
     * @notice Sets new address for fee recipient.
     * @dev Requirements:
     * - should be called by owner
     * - fee recipient should not be the zero address
     * @param _newFeeRecipient New fee recipient.
     */
    function setFeeRecipient(address _newFeeRecipient) external onlyOwner {
        _setFeeRecipient(_newFeeRecipient);
    }

    /**
     * @notice Allows tokens to be used for fee deposits.
     * @dev Requirements:
     * - should be called by owner
     * @param _allowedTokens Tokens to allow.
     */
    function allowTokens(IERC20Upgradeable[] calldata _allowedTokens) external onlyOwner {
        _allowTokens(_allowedTokens);
    }

    /**
     * @notice Disallows tokens to be used for fee deposits.
     * @dev Requirements:
     * - should be called by owner
     * @param _disallowedTokens Tokens to disallow.
     */
    function disallowTokens(IERC20Upgradeable[] calldata _disallowedTokens)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _disallowedTokens.length; i++) {
            allowedTokens[_disallowedTokens[i]] = false;
        }

        emit TokensDisallowed(_disallowedTokens);
    }

    /**
     * @notice Adds new fee collectors.
     * @dev Requirements:
     * - should be called by owner
     * @param _feeCollectorsUpdate Fee collectors to add.
     */
    function addFeeCollectors(address[] calldata _feeCollectorsUpdate)
        external
        onlyOwner
    {
        _addFeeCollectors(_feeCollectorsUpdate);
    }

    /**
     * @notice Removes current fee collectors.
     * @dev Requirements:
     * - should be called by owner
     * @param _feeCollectorsUpdate Fee collectors to remove.
     */
    function removeFeeCollectors(address[] calldata _feeCollectorsUpdate)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _feeCollectorsUpdate.length; i++) {
            feeCollectors[_feeCollectorsUpdate[i]] = false;
        }

        emit FeeCollectorsRemoved(_feeCollectorsUpdate);
    }

    /**
     * @dev Sets new fee recipient.
     * Checks that fee recipient is not the zero address.
     */
    function _setFeeRecipient(address _newFeeRecipient) private {
        require(
            _newFeeRecipient != address(0),
            "FeeManager::_setFeeRecipient: New fee recipient is the zero address."
        );

        address oldRecipient = feeRecipient;
        feeRecipient = _newFeeRecipient;

        emit FeeRecipientSet(oldRecipient, _newFeeRecipient);
    }

    /**
     * @dev Allows tokens to be used for fee deposits.
     */
    function _allowTokens(IERC20Upgradeable[] calldata _allowedTokens) private {
        for (uint256 i = 0; i < _allowedTokens.length; i++) {
            allowedTokens[_allowedTokens[i]] = true;
        }

        emit TokensAllowed(_allowedTokens);
    }

    /**
     * @dev Adds fee collectors.
     */
    function _addFeeCollectors(address[] calldata _feeCollectors) private {
        for (uint256 i = 0; i < _feeCollectors.length; i++) {
            feeCollectors[_feeCollectors[i]] = true;
        }

        emit FeeCollectorsAdded(_feeCollectors);
    }

    /* ========== TEAM MANAGEMENT FUNCTIONS ========== */

    /**
     * @notice Creates a new team.
     * Team owner can mange the team and is allowed to withdraw fees.
     * @dev Requirements:
     * - should be called with unique `_teamId`.
     * - team owner should not be the zero address
     * @param _teamId Unique identifier for the team.
     * @param _teamOwner Team owner.
     * @param _withdrawalAllowList List of addresses that are allowed to withdraw fees for the team.
     */
    function createTeam(
        string calldata _teamId,
        address _teamOwner,
        address[] calldata _withdrawalAllowList
    ) external {
        require(!teams[_teamId].valid, "FeeManager::createTeam: Team already exists.");

        // Create the team.
        teams[_teamId] = Team({ id: _teamId, owner: address(0), valid: true });

        // Set everything for new team.
        _transferTeamOwnership(_teamId, _teamOwner);
        _addPermissionForWithdrawalForTeam(_teamId, _withdrawalAllowList);

        emit TeamCreated(_teamId, _teamId);
    }

    /**
     * @notice Transfers ownership of the team to a new owner.
     * @dev Requirements:
     * - should be called for a valid team
     * - should be called by team's owner
     * - new owner should not be the zero address
     * @param _teamId Team's identifier.
     * @param _newOwner New team owner.
     */
    function transferTeamOwnership(string calldata _teamId, address _newOwner)
        external
        isValidTeam(_teamId)
        onlyTeamOwner(_teamId)
    {
        _transferTeamOwnership(_teamId, _newOwner);
    }

    /**
     * @notice Adds addresses to the list of addresses that are allowed to withdraw fees for the team.
     * @dev Requirements:
     * - should be called for a valid team
     * - should be called by team's owner
     * @param _teamId Team identifier.
     * @param _withdrawalAllowListUpdate Whom to add permissions.
     */
    function addPermissionForWithdrawalForTeam(
        string calldata _teamId,
        address[] calldata _withdrawalAllowListUpdate
    ) external isValidTeam(_teamId) onlyTeamOwner(_teamId) {
        _addPermissionForWithdrawalForTeam(_teamId, _withdrawalAllowListUpdate);
    }

    /**
     * @notice Removes addresses from the list of addresses that are allowed to withdraw fees for the team.
     * @dev Requirements:
     * - should be called for a valid team
     * - should be called by team's owner
     * @param _teamId Team identifier.
     * @param _withdrawalAllowListUpdate Whom to remove permissions.
     */
    function removePermissionForWithdrawalForTeam(
        string calldata _teamId,
        address[] calldata _withdrawalAllowListUpdate
    ) external isValidTeam(_teamId) onlyTeamOwner(_teamId) {
        for (uint256 i = 0; i < _withdrawalAllowListUpdate.length; i++) {
            withdrawalAllowList[_teamId][_withdrawalAllowListUpdate[i]] = false;
        }

        emit WithdrawalPermissionForTeamRemoved(_teamId, _withdrawalAllowListUpdate);
    }

    /**
     * @notice Checks if a user is allowed to withdraw fees for the team.
     * Users are allowed to withdraw if
     * - they are the team owner
     * - they are on the withdrawal allow-list for the team
     * @dev Requirements:
     * - should be called for a valid team
     * @param _teamId Team identifier.
     * @param _user User whose permissions to check.
     * @return True, if user is allowed, false otherwise.
     */
    function isAllowedToWithdrawForTeam(string calldata _teamId, address _user)
        public
        view
        isValidTeam(_teamId)
        returns (bool)
    {
        return teams[_teamId].owner == _user || withdrawalAllowList[_teamId][_user];
    }

    /**
     * @dev Transfers ownership of the team to a new owner.
     * Checks that team owner is not the zero address.
     */
    function _transferTeamOwnership(string calldata _teamId, address _newOwner) private {
        require(
            _newOwner != address(0),
            "FeeManager::_transferTeamOwnership: New team owner is the zero address."
        );

        address oldOwner = teams[_teamId].owner;
        teams[_teamId].owner = _newOwner;

        emit TeamOwnershipTransferred(_teamId, oldOwner, _newOwner);
    }

    /**
     * @dev Adds addresses to the list of addresses that are allowed to withdraw fees for the team.
     */
    function _addPermissionForWithdrawalForTeam(
        string calldata _teamId,
        address[] calldata _withdrawalAllowListUpdate
    ) private {
        for (uint256 i = 0; i < _withdrawalAllowListUpdate.length; i++) {
            withdrawalAllowList[_teamId][_withdrawalAllowListUpdate[i]] = true;
        }

        emit WithdrawalPermissionForTeamAdded(_teamId, _withdrawalAllowListUpdate);
    }

    /* ========== BALANCE MANAGEMENT FUNCTIONS ========== */

    /**
     * @notice Deposits fee for a team.
     * Transaction of tokens must fist be approved by the caller on the token contract.
     * @dev Requirements:
     * - should be called for a valid team
     * - should be called with token from allow-list
     * This function must first sync balance book for team-token.
     * @param _teamId Team identifier.
     * @param _amount Amount to deposit.
     * @param _token Token to deposit.
     */
    function depositFee(
        string calldata _teamId,
        uint256 _amount,
        IERC20Upgradeable _token
    )
        external
        isValidTeam(_teamId)
        isAllowedToken(_token)
        syncBalanceBook(_teamId, _token)
    {
        // Transfer tokens and update balance.
        _token.safeTransferFrom(msg.sender, address(this), _amount);
        _balanceBook[_teamId][_token].balance += _amount;

        emit FeeDeposited(_teamId, _token, _amount);
    }

    /**
     * @notice Collects fees from teams.
     * Collected fees are transfered to the fee recipient.
     * Balance available for collection is `balance - claimableWithdrawals`.
     * @dev Requirements:
     * - should be called by owner
     * - should be called with parameters of equal length
     * - should be called with valid teams.
     * - team should have enough available balance
     * This function must first sync balance book for team-token before collection fees.
     * @param _teams Teams' identifiers.
     * @param _amounts Amounts to collect.
     * @param _tokens Tokens to collect.
     */
    function collectFees(
        string[] calldata _teams,
        uint256[] calldata _amounts,
        IERC20Upgradeable[] calldata _tokens
    ) external onlyFeeCollector {
        // Check that lenghts of parameters match.
        require(
            (_teams.length == _amounts.length) && (_teams.length == _tokens.length),
            "FeeManager::collectFees: Parameter length mismatch."
        );

        // Loop over each triplet.
        for (uint256 i = 0; i < _teams.length; i++) {
            // Check that the team is valid.
            _isValidTeam(_teams[i]);

            // Need to sync balance book for team-token to get currently available balance.
            _syncBalanceBook(_teams[i], _tokens[i]);

            // Check that there is enough balance for collection.
            require(
                _balanceBook[_teams[i]][_tokens[i]].balance -
                    _balanceBook[_teams[i]][_tokens[i]].claimableWithdrawals >=
                    _amounts[i],
                "FeeManager::collectFees: Not enough available balance left."
            );

            // Update balance and transfer tokens.
            unchecked {
                _balanceBook[_teams[i]][_tokens[i]].balance -= _amounts[i];
            }
            _tokens[i].safeTransfer(feeRecipient, _amounts[i]);

            emit FeeCollected(_teams[i], _tokens[i], _amounts[i]);
        }

        // Enter new fee collection cycle.
        feeCollectionCycle++;
        emit FeeCollectionComplete(feeCollectionCycle);
        // Could sync at this point also, but it is not strictly needed.
    }

    /**
     * @notice Requests fee withdrawal.
     * This does not withdraw fees, but only requests withdrawal.
     * Fee withdrawal can be claimed in the next fee collection cycle.
     * Balance available for withdrawal request is
     * `balance - claimableWithdrawals - unclaimableWithdrawals`.
     * Multiple calls for same team-token will increase total requested amount.
     * @dev Requirements:
     * - should be called for a valid team
     * - should be called by user on withdrawal allow-list for the team
     * - team should have enough available balance
     * This function must first sync balance book for team-token.
     * @param _teamId Team identifier.
     * @param _amount Amount requested to withdraw.
     * @param _token Token requested to withdraw.
     */
    function requestFeeWithdrawal(
        string calldata _teamId,
        uint256 _amount,
        IERC20Upgradeable _token
    )
        external
        isValidTeam(_teamId)
        isAllowedToWithdraw(_teamId)
        syncBalanceBook(_teamId, _token)
    {
        // Check that there is enough available balance for withdrawal request.
        require(
            _balanceBook[_teamId][_token].balance -
                _balanceBook[_teamId][_token].claimableWithdrawals -
                _balanceBook[_teamId][_token].unclaimableWithdrawals >=
                _amount,
            "FeeManager::requestFeeWithdrawal: Not enough available balance left."
        );

        // Update balance.
        _balanceBook[_teamId][_token].unclaimableWithdrawals += _amount;

        emit FeeWithdrawalRequested(_teamId, _token, _amount);
    }

    /**
     * @notice Claims requested fee withdrawal.
     * Can claim up to amount requested in previous fee collection cycle.
     * Amount can be lowered by collected fees when requested amount
     * and fees were larger than available balance.
     * Can claim in multiple installments by multiple users.
     * @dev Requirements:
     * - should be called for a valid team
     * - should be called by user on withdrawal allow-list for the team
     * - team should have enough available balance
     * This function must first sync balance book for team-token.
     * @param _teamId Team identifier.
     * @param _amount Amount to claim.
     * @param _token Token to claim.
     */
    function claimFeeWithdrawal(
        string calldata _teamId,
        uint256 _amount,
        IERC20Upgradeable _token
    )
        external
        isValidTeam(_teamId)
        isAllowedToWithdraw(_teamId)
        syncBalanceBook(_teamId, _token)
    {
        BalanceBookEntry storage balanceBookEntry = _balanceBook[_teamId][_token];

        // Check that there is enough available balance for withdrawal claim.
        require(
            balanceBookEntry.claimableWithdrawals >= _amount,
            "FeeManager::claimFeeWithdrawal: Claimed amount is larger than requested amount."
        );

        // Update balance and transfer tokens.
        balanceBookEntry.balance -= _amount;
        unchecked {
            balanceBookEntry.claimableWithdrawals -= _amount;
        }
        _token.safeTransfer(msg.sender, _amount);

        emit FeeWithdrawalClaimed(_teamId, _token, _amount);
    }

    /**
     * @notice Gets balance for team-token.
     * @dev This function must return synced balance for team-token.
     * Requirements
     * - should be called for a valid team
     * @param _teamId Team identifier.
     * @param _token Token.
     * @return Balance for team-token.
     */
    function getBalance(string calldata _teamId, IERC20Upgradeable _token)
        external
        view
        isValidTeam(_teamId)
        returns (BalanceReport memory)
    {
        BalanceBookEntry memory entry = _getBalance(_teamId, _token);

        return
            BalanceReport({
                balance: entry.balance,
                claimableWithdrawals: entry.claimableWithdrawals,
                unclaimableWithdrawals: entry.unclaimableWithdrawals,
                collectableBalance: entry.balance - entry.claimableWithdrawals,
                requestableBalance: entry.balance -
                    entry.claimableWithdrawals -
                    entry.unclaimableWithdrawals
            });
    }

    /**
     * @dev Gets synced balance for team-token.
     * @param _teamId Team identifier.
     * @param _token Token.
     * @return Balance for team-token.
     */
    function _getBalance(string calldata _teamId, IERC20Upgradeable _token)
        private
        view
        returns (BalanceBookEntry memory)
    {
        BalanceBookEntry memory balanceBookEntry = _balanceBook[_teamId][_token];

        // Need to sync if it was not synced within current fee collection cycle.
        if (balanceBookEntry.lastSynced < feeCollectionCycle) {
            // Transfer withdrawal requests to balance available for withdrawal claims.
            balanceBookEntry.claimableWithdrawals += balanceBookEntry
                .unclaimableWithdrawals;
            balanceBookEntry.unclaimableWithdrawals = 0;

            // Update sync info.
            balanceBookEntry.lastSynced = feeCollectionCycle;

            // Balance available for withdrawal claims cannot be larger than token balance.
            if (balanceBookEntry.claimableWithdrawals > balanceBookEntry.balance) {
                balanceBookEntry.claimableWithdrawals = balanceBookEntry.balance;
            }
        }

        return balanceBookEntry;
    }

    /**
     * @dev Syncs balance book.
     * @param _teamId Team identifier.
     * @param _token Token.
     */
    function _syncBalanceBook(string calldata _teamId, IERC20Upgradeable _token) private {
        // Sync if needed.
        if (_balanceBook[_teamId][_token].lastSynced < feeCollectionCycle) {
            _balanceBook[_teamId][_token] = _getBalance(_teamId, _token);
        }
    }

    /* ========== RESTRICTION FUNCTIONS ========== */

    /**
     * @notice Ensures that token is allowed.
     */
    function _isAllowedToken(IERC20Upgradeable _token) private view {
        require(
            allowedTokens[_token],
            "FeeManager::_isAllowedToken: Token must be allowed."
        );
    }

    /**
     * @notice Ensures that caller is fee collector.
     */
    function _onlyFeeCollector() private view {
        require(
            feeCollectors[msg.sender],
            "FeeManager::_onlyFeeCollector: Caller must be a fee collector."
        );
    }

    /**
     * @notice Ensures that caller is team owner.
     */
    function _onlyTeamOwner(string calldata _teamId) private view {
        require(
            teams[_teamId].owner == msg.sender,
            "FeeManager::_onlyTeamOwner: Caller must be a team owner."
        );
    }

    /**
     * @notice Ensures that team is valid.
     */
    function _isValidTeam(string calldata _teamId) private view {
        require(teams[_teamId].valid, "FeeManager::_isValidTeam: Team must be valid.");
    }

    /**
     * @notice Ensures that caller is allowed to withdraw for the team.
     */
    function _isAllowedToWithdraw(string calldata _teamId) private view {
        require(
            isAllowedToWithdrawForTeam(_teamId, msg.sender),
            "FeeManager::_isAllowedToWithdraw: User must be allowed to withdraw."
        );
    }

    /* ========== MODIFIERS ========== */

    /**
     * @notice Throws if token is not allowed.
     */
    modifier isAllowedToken(IERC20Upgradeable _token) {
        _isAllowedToken(_token);
        _;
    }

    /**
     * @notice Throws if caller is not fee collector.
     */
    modifier onlyFeeCollector() {
        _onlyFeeCollector();
        _;
    }

    /**
     * @notice Syncs balance book entry for team-token.
     */
    modifier syncBalanceBook(string calldata _teamId, IERC20Upgradeable _token) {
        _syncBalanceBook(_teamId, _token);
        _;
    }

    /**
     * @notice Throws if caller is not team owner.
     */
    modifier onlyTeamOwner(string calldata _teamId) {
        _onlyTeamOwner(_teamId);
        _;
    }

    /**
     * @notice Throws if team is not valid.
     */
    modifier isValidTeam(string calldata _teamId) {
        _isValidTeam(_teamId);
        _;
    }

    /**
     * @notice Throws if caller is not allowed to withdraw for team.
     */
    modifier isAllowedToWithdraw(string calldata _teamId) {
        _isAllowedToWithdraw(_teamId);
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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