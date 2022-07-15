// SPDX-License-Identifier: MIT
pragma solidity >=0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/// Multisig controlled by 2 groups: admins and owners. 
/// Admins can add and remove admins and owners and set the confirmations required from each.
/// Some number of confirmations are required from both admins and owners for transactions
/// to be executed.
contract MultiSigWallet {
    using SafeERC20 for IERC20;
    
    event Deposit(address indexed sender, uint256 amount, uint256 balance);
    event SubmitTransaction(
        address indexed owner,
        uint256 indexed txIndex,
        address indexed to,
        uint256 value,
        bytes data
    );
    event ConfirmTransaction(
        address indexed admin, 
        uint256 indexed txIndex,
        uint256 adminConfirmations,
        uint256 ownerConfirmations
    );
    event RevokeConfirmation(
        address indexed owner, 
        uint256 indexed txIndex,
        uint256 adminConfirmations,
        uint256 ownerConfirmations
    );
    event ExecuteTransaction(uint256 indexed txIndex);

    event AddAdmin(address indexed admin, address[] indexed admins);
    event AddOwner(address indexed owner, address[] indexed owners);
    
    event RemoveAdmin(address indexed admin, address[] indexed admins);
    event RemoveOwner(address indexed owner, address[] indexed owners);

    event SetAdminConfirmationsRequired(uint256 indexed adminConfirmationsRequired);
    event SetOwnerConfirmationsRequired(uint256 indexed ownerConfirmationsRequired);

    event Transfer(address indexed token, address indexed to, uint256 indexed amount);

    error AlreadyAnOwner(address owner);
    error AlreadyAnAdmin(address admin);

    error NotAnAdmin(address caller);
    error NotAnOwner(address caller);
    error NotAnAdminOrOwner(address caller);

    error OwnersAreRequired();
    error ConfirmationsRequiredCantBeZero();
    error MsgSenderIsNotThis(address msgSender);
    error ZeroAddress();

    error OwnerCantBeAdmin(address owner);
    error AdminCantBeOwner(address admin);

    error TxDoesNotExist(uint256 txIndex);
    error TxAlreadyExecuted(uint256 txIndex);
    error TxAlreadyConfirmed(uint256 txIndex);
    error TxFailed(uint256 txIndex);
    error TxNotConfirmed(uint256 txIndex);

    error InsufficientAdminConfirmations(uint256 numConfirmations, uint256 numRequired);
    error InsufficientOwnerConfirmations(uint256 numConfirmations, uint256 numRequired);
    error ConfirmationsRequiredAboveMax(uint256 confirmationsRequired, uint256 max);
    error ArrayLengthBelowMinLength(uint256 length, uint256 minLength);

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 adminConfirmations;
        uint256 ownerConfirmations;
    }

    Transaction[] public transactions;

    address[] public admins;
    mapping(address => bool) public isAdmin;
    uint256 public adminConfirmationsRequired;

    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public ownerConfirmationsRequired;

    // mapping from tx index => admin/owner => true if admin/owner has confirmed and false otherwise
    mapping(uint256 => mapping(address => bool)) public isConfirmed;

    modifier onlyAdminOrOwner() {
        if (!isOwner[msg.sender] && !isAdmin[msg.sender]) revert NotAnAdminOrOwner(msg.sender);
        _;
    }

    modifier txExists(uint256 _txIndex) {
        if (_txIndex >= transactions.length) revert TxDoesNotExist(_txIndex);
        _;
    }

    modifier notExecuted(uint256 _txIndex) {
        if (transactions[_txIndex].executed) revert TxAlreadyExecuted(_txIndex);
        _;
    }

    modifier notConfirmed(uint256 _txIndex) {
        if (isConfirmed[_txIndex][msg.sender]) revert TxAlreadyConfirmed(_txIndex);
        _;
    }

    modifier onlyConfirmed(uint256 _txIndex) {
        if (!isConfirmed[_txIndex][msg.sender]) revert TxNotConfirmed(_txIndex);
        _;
    }

    modifier onlyThis() {
        if (msg.sender != address(this)) revert MsgSenderIsNotThis(msg.sender);
        _;
    }

    /// WARNING: If _admins is empty the setters in this contract will not be callable
    constructor(
        address[] memory _admins,
        address[] memory _owners,
        uint256 _adminConfirmationsRequired,
        uint256 _ownerConfirmationsRequired
    ) {
        if (_owners.length == 0) revert OwnersAreRequired();
        if (_adminConfirmationsRequired > _admins.length) {
            revert ConfirmationsRequiredAboveMax(_adminConfirmationsRequired, _admins.length);
        }
        if (_ownerConfirmationsRequired == 0) 
            revert ConfirmationsRequiredCantBeZero();
        if (_ownerConfirmationsRequired > _owners.length) {
            revert ConfirmationsRequiredAboveMax(_ownerConfirmationsRequired, _owners.length);
        }

        uint256 adminsLength = _admins.length;
        for (uint256 i = 0; i < adminsLength; i++) {
            address admin = _admins[i];

            if (admin == address(0)) revert ZeroAddress();
            if (isAdmin[admin]) revert AlreadyAnAdmin(admin);

            isAdmin[admin] = true;
            admins.push(admin);
        }

        uint256 ownersLength = _owners.length;
        for (uint256 i = 0; i < ownersLength; i++) {
            address owner = _owners[i];

            if (owner == address(0)) revert ZeroAddress();
            if (isAdmin[owner]) revert OwnerCantBeAdmin(owner);
            if (isOwner[owner]) revert AlreadyAnOwner(owner);

            isOwner[owner] = true;
            owners.push(owner);
        }

        adminConfirmationsRequired = _adminConfirmationsRequired;
        ownerConfirmationsRequired = _ownerConfirmationsRequired;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    /// Submit a transaction to transfer _amount of _token to _to
    function submitTransfer(address _token, address _to, uint256 _amount) external {
        bytes memory data = abi.encodeWithSignature(
            "_transfer(address,address,uint256)", 
            _token,
            _to,
            _amount
        );
        submitTransaction(address(this), 0, data);
    }

    /// Submit a transaction to add a new _admin
    function submitAddAdmin(address _admin) external {
        bytes memory data = abi.encodeWithSignature("_addAdmin(address)", _admin);
        submitTransaction(address(this), 0, data);
    }

    /// Submit a transaction to add a new _owner
    function submitAddOwner(address _owner) external {
        bytes memory data = abi.encodeWithSignature("_addOwner(address)", _owner);
        submitTransaction(address(this), 0, data);
    }

    /// Submit a transaction to remove _admin
    function submitRemoveAdmin(address _admin) external {
        bytes memory data = abi.encodeWithSignature("_removeAdmin(address)", _admin);
        submitTransaction(address(this), 0, data);
    }

    /// Submit a transaction to remove _owner
    function submitRemoveOwner(address _owner) external {
        bytes memory data = abi.encodeWithSignature("_removeOwner(address)", _owner);
        submitTransaction(address(this), 0, data);
    }

    /// Submit a transaction to set the number of admin confirmations required to execute 
    /// transactions
    function submitSetAdminConfirmationsRequired(uint256 _adminConfirmationsRequired) external {
        bytes memory data = abi.encodeWithSignature(
            "_setAdminConfirmationsRequired(uint256)", 
            _adminConfirmationsRequired
        );
        submitTransaction(address(this), 0, data);
    }

    /// Submit a transaction to set the number of owner confirmations required to execute
    /// transactions
    function submitSetOwnerConfirmationsRequired(uint256 _ownerConfirmationsRequired) external {
        bytes memory data = abi.encodeWithSignature(
            "_setOwnerConfirmationsRequired(uint256)", 
            _ownerConfirmationsRequired
        );
        submitTransaction(address(this), 0, data);
    }

    /// Return the array of admins
    function getAdmins() external view returns (address[] memory) {
        return admins;
    }

    /// Return the array of owners
    function getOwners() external view returns (address[] memory) {
        return owners;
    }

    /// Return the number of transactions that have been submitted
    function getTransactionCount() external view returns (uint) {
        return transactions.length;
    }

    /// Return the transaction with _txIndex
    function getTransaction(uint256 _txIndex)
        external  
        view
        returns (
            address to,
            uint256 value,
            bytes memory data,
            bool executed,
            uint256 ownerConfirmations,
            uint256 adminConfirmations
        )
    {
        Transaction memory transaction = transactions[_txIndex];

        return (
            transaction.to,
            transaction.value,
            transaction.data,
            transaction.executed,
            transaction.ownerConfirmations,
            transaction.adminConfirmations
        );
    }

    /// Return this contract's _token balance
    function getBalance(address _token) external view returns (uint256) {
        if (_token == address(0)) revert ZeroAddress();
        return IERC20(_token).balanceOf(address(this));
    }

    /// Submit a new transaction for admin and owner confirmation
    function submitTransaction(
        address _to,
        uint256 _value,
        bytes memory _data
    ) 
        public 
        onlyAdminOrOwner 
    {
        uint256 txIndex = transactions.length;

        transactions.push(
            Transaction({
                to: _to,
                value: _value,
                data: _data,
                executed: false,
                adminConfirmations: 0,
                ownerConfirmations: 0
            })
        );

        emit SubmitTransaction(msg.sender, txIndex, _to, _value, _data);
    }

    /// Confirm that transaction with _txIndex can be executed
    function confirmTransaction(uint256 _txIndex)
        public
        onlyAdminOrOwner
        txExists(_txIndex)
        notConfirmed(_txIndex)
        notExecuted(_txIndex)
    {
        isConfirmed[_txIndex][msg.sender] = true;

        Transaction storage transaction = transactions[_txIndex];
        if (isAdmin[msg.sender]) {
            transaction.adminConfirmations += 1;
        } else {
            transaction.ownerConfirmations += 1;
        }

        emit ConfirmTransaction(
            msg.sender, 
            _txIndex, 
            transaction.adminConfirmations, 
            transaction.ownerConfirmations
        );
    }

    /// Revoke confirmation for transaction with _txIndex
    function revokeConfirmation(uint256 _txIndex)
        public
        onlyAdminOrOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
        onlyConfirmed(_txIndex)
    {
        isConfirmed[_txIndex][msg.sender] = false;

        Transaction storage transaction = transactions[_txIndex];
        if (isAdmin[msg.sender]) {
            transaction.adminConfirmations -= 1;
        } else {
            transaction.ownerConfirmations -= 1;
        }

        emit RevokeConfirmation(
            msg.sender, 
            _txIndex,
            transaction.adminConfirmations,
            transaction.ownerConfirmations
        );
    }

    /// Execute the transaction with _txIndex
    function executeTransaction(uint256 _txIndex)
        public
        virtual
        onlyAdminOrOwner
        txExists(_txIndex)
        notExecuted(_txIndex)
    {
        Transaction storage transaction = transactions[_txIndex];

        uint256 adminConfirmations = transaction.adminConfirmations;
        if (adminConfirmations < adminConfirmationsRequired) {
            revert InsufficientAdminConfirmations(
                adminConfirmations, 
                adminConfirmationsRequired
            );
        }

        uint256 ownerConfirmations = transaction.ownerConfirmations;
        if (ownerConfirmations < ownerConfirmationsRequired) {
            revert InsufficientOwnerConfirmations(
                ownerConfirmations, 
                ownerConfirmationsRequired
            );
        }

        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value}(
            transaction.data
        );
        if (!success) revert TxFailed(_txIndex);

        emit ExecuteTransaction(_txIndex);
    }

    /// Not externally callable
    /// Transfer _amount of _token to _to
    function _transfer(address _token, address _to, uint256 _amount) public onlyThis {
        IERC20(_token).safeTransfer(_to, _amount);
        emit Transfer(_token, _to, _amount);
    }

    /// Not externally callable
    /// Add _admin as an admin
    function _addAdmin(address _admin) public onlyThis {
        if (isAdmin[_admin]) revert AlreadyAnAdmin(_admin);
        if (isOwner[_admin]) revert AdminCantBeOwner(_admin);
        isAdmin[_admin] = true;
        admins.push(_admin);
        emit AddAdmin(_admin, admins);
    }

    /// Not externally callable
    /// Add _owner as an owner
    function _addOwner(address _owner) public onlyThis {
        if (isOwner[_owner]) revert AlreadyAnOwner(_owner);
        if (isAdmin[_owner]) revert OwnerCantBeAdmin(_owner);
        isOwner[_owner] = true;
        owners.push(_owner);
        emit AddOwner(_owner, owners);
    }

    /// Not externally callable
    /// Remove _admin from being an admin
    function _removeAdmin(address _admin) public onlyThis {
        if (!isAdmin[_admin]) revert NotAnAdmin(_admin);
        uint256 adminsLength = admins.length;
        if (adminsLength - 1 < adminConfirmationsRequired) {
            revert ArrayLengthBelowMinLength(
                adminsLength - 1, 
                adminConfirmationsRequired
            );
        }
        for (uint256 i = 0; i < adminsLength; i++) {
            if (admins[i] == _admin) {
                isAdmin[_admin] = false;

                admins[i] = admins[adminsLength - 1];
                admins.pop();

                emit RemoveAdmin(_admin, admins);
                return;
            }
        }
    }

    /// Not externally callable
    /// Remove _owner from being an owner
    function _removeOwner(address _owner) public onlyThis {
        if (!isOwner[_owner]) revert NotAnOwner(_owner);
        uint256 ownersLength = owners.length;
        if (ownersLength - 1 < ownerConfirmationsRequired) {
            revert ArrayLengthBelowMinLength(
                ownersLength - 1, 
                ownerConfirmationsRequired
            );
        }
        for (uint256 i = 0; i < ownersLength; i++) {
            if (owners[i] == _owner) {
                isOwner[_owner] = false;

                owners[i] = owners[ownersLength - 1];
                owners.pop();

                emit RemoveOwner(_owner, owners);
                return;
            }
        }
    }

    /// Not externally callable
    /// Set the _ownerConfirmationsRequired for transactions be be executed
    function _setAdminConfirmationsRequired(uint256 _adminConfirmationsRequired) public onlyThis {
        if (_adminConfirmationsRequired > admins.length) {
            revert ConfirmationsRequiredAboveMax(_adminConfirmationsRequired, admins.length);
        }
 
        adminConfirmationsRequired = _adminConfirmationsRequired;
        emit SetAdminConfirmationsRequired(_adminConfirmationsRequired);
    }

    /// Not externally callable
    /// Set the _ownerConfirmationsRequired for transactions be be executed
    function _setOwnerConfirmationsRequired(uint256 _ownerConfirmationsRequired) public onlyThis {
        if (_ownerConfirmationsRequired == 0) revert ConfirmationsRequiredCantBeZero();
        if (_ownerConfirmationsRequired > owners.length) {
            revert ConfirmationsRequiredAboveMax(_ownerConfirmationsRequired, owners.length);
        }

        ownerConfirmationsRequired = _ownerConfirmationsRequired;
        emit SetOwnerConfirmationsRequired(_ownerConfirmationsRequired);
    }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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