// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './CreditLedger.sol';

contract Xeenon is CreditLedger {
  using SafeERC20 for IERC20;

  // Rate types
  uint128 public constant PERCENTAGE_RATE = 1;
  uint128 public constant FIXED_RATE = 2;

  /**
   * Component that holds values to represent different transfer options.
   * code can be 1 `PERCENTAGE_RATE` | 2 `FIXED_RATE`
   * `PERCENTAGE_RATE` is stored in values 0 - 1000 representing 0.0 - 100.0 %
   */
  struct FeeComponent {
    uint128 code;
    uint128 value;
  }

  struct BatchTransferUnit {
    address from;
    address to;
    uint256 creditAmount;
  }

  struct BatchTransferUnitWithKey {
    address from;
    address to;
    uint256 creditAmount;
    bytes32 key;
  }

  mapping(bytes32 => FeeComponent) public feeComponents;

  // In case of breach of admin wallet or user needs to take action, freeze withdraw to protect users.
  bool private withdrawFrozen;
  mapping(address => bool) private frozenWithdrawWallets;

  event Deposit(address indexed from, uint256 deposit, uint256 creditsAfter);
  event Withdraw(address indexed from, uint256 withdraw, uint256 creditsAfter);
  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value,
    uint256 fee,
    uint256 fromCreditsAfter,
    uint256 toCreditsAfter,
    bytes32 key
  );
  event BatchTransfer(bytes32 indexed id);
  event SingleTransfer(bytes32 indexed id);
  event GlobalFreeze();
  event WalletFreeze(address wallet);

  constructor(
    IERC20 _acceptedToken,
    address _admin,
    address _treasuryReceiver
  ) CreditLedger(_acceptedToken, _admin, _treasuryReceiver) {
    FeeComponent storage depositFee = feeComponents['deposit'];
    depositFee.code = FIXED_RATE;
    depositFee.value = 0;

    FeeComponent storage withdrawFee = feeComponents['withdraw'];
    withdrawFee.code = FIXED_RATE;
    withdrawFee.value = 0;
  }

  // Fee component functionality

  function addFeeComponent(
    bytes32 _key,
    uint128 _code,
    uint128 _value
  ) external onlyOwner {
    require(_code == PERCENTAGE_RATE || _code == FIXED_RATE, 'Invalid code');
    if (_code == PERCENTAGE_RATE) {
      require(_key != 'deposit' && _key != 'withdraw', "Deposit/withdraw fee can't be percentage fee");
      _addPercentageRate(_key, _value);
    } else {
      _addFixedRate(_key, _value);
    }
  }

  function _addPercentageRate(bytes32 _key, uint128 _value) private {
    require(_value <= 1000, "_value can't be more than 1000.");

    FeeComponent storage feeComponent = feeComponents[_key];
    feeComponent.code = PERCENTAGE_RATE;
    feeComponent.value = _value;
  }

  function _addFixedRate(bytes32 _key, uint128 _value) private {
    FeeComponent storage feeComponent = feeComponents[_key];
    feeComponent.code = FIXED_RATE;
    feeComponent.value = _value;
  }

  function deleteFeeComponent(bytes32 _key) external onlyOwner {
    require(feeComponents[_key].code != 0, 'Key does not exist.');
    delete feeComponents[_key];
  }

  /**
   *  @notice Depositing  to receive credits.
   *  @param _amount uint256
   */
  function deposit(uint256 _amount) external {
    uint256 depositFee = feeComponents['deposit'].value;
    uint256 creditAmount = convertToCredits(_amount);

    require(creditAmount > depositFee, "Can't deposit less than fee.");

    acceptedToken.safeTransferFrom(msg.sender, address(this), _amount);

    if (depositFee > 0) {
      _addRevenue(depositFee);
      _addCredits(msg.sender, creditAmount - depositFee);
    } else {
      _addCredits(msg.sender, creditAmount);
    }

    if (!frozenWithdrawWallets[msg.sender]) {
      _freezeWalletWithdraw(msg.sender);
    }

    emit Deposit(
      msg.sender,
      convertToCredits(_amount),
      creditBalance(msg.sender)
    );
  }

  /**
   *  @notice Converting credits to DAI.
   *  @param _creditAmount uint256
   */
  function withdraw(uint256 _creditAmount) external {
    uint256 withdrawFee = feeComponents['withdraw'].value;

    require(
      creditBalance(msg.sender) >= _creditAmount,
      "You don't have enough credits."
    );
    require(_creditAmount > withdrawFee, "Can't withdraw more than fee.");
    require(!withdrawFrozen, 'Withdraws are frozen.');
    require(!frozenWithdrawWallets[msg.sender], 'Withdraws are frozen.');

    _removeCredits(msg.sender, _creditAmount);
    if (withdrawFee > 0) {
      _addRevenue(withdrawFee);
      acceptedToken.safeTransfer(
        msg.sender,
        convertFromCredits(_creditAmount - withdrawFee)
      );
    } else {
      acceptedToken.safeTransfer(msg.sender, convertFromCredits(_creditAmount));
    }

    _freezeWalletWithdraw(msg.sender);

    emit Withdraw(msg.sender, _creditAmount, creditBalance(msg.sender));
  }

  // Freezing functionality

  function freezeWithdraw() external onlyAdmin {
    withdrawFrozen = true;
    emit GlobalFreeze();
  }

  function unFreezeWithdraw() external onlyOwner {
    withdrawFrozen = false;
  }

  function isWalletFrozen(address _wallet) external view returns (bool) {
    return frozenWithdrawWallets[_wallet];
  }

  function freezeWalletWithdraw(address _wallet) external onlyRole(FREEZE) {
    _freezeWalletWithdraw(_wallet);
  }

  function freezeWalletWithdraw() external {
    _freezeWalletWithdraw(msg.sender);
  }

  function _freezeWalletWithdraw(address _wallet) private {
    frozenWithdrawWallets[_wallet] = true;
    emit WalletFreeze(_wallet);
  }

  function unFreezeWalletWithdraw(address _wallet) external onlyRole(FREEZE) {
    require(frozenWithdrawWallets[_wallet], 'Wallet was not frozen.');
    delete frozenWithdrawWallets[_wallet];
  }

  function transfer(
    address _from,
    address _to,
    uint256 _creditAmount,
    bytes32 _key,
    bytes32 _transferId
  ) external onlyRole(TRANSFER) {
    _transfer(_from, _to, _creditAmount, _key);
    emit SingleTransfer(_transferId);
  }

  function batchTransfer(
    BatchTransferUnitWithKey[] calldata _transfers,
    bytes32 _batchId
  ) external onlyRole(TRANSFER) {
    for (uint256 i = 0; i < _transfers.length; i++) {
      _transfer(_transfers[i].from, _transfers[i].to, _transfers[i].creditAmount, _transfers[i].key);
    }
    emit BatchTransfer(_batchId);
  }

  function batchTransferByKey(
    BatchTransferUnit[] calldata _transfers,
    bytes32 _key,
    bytes32 _batchId
  ) external onlyRole(TRANSFER) {
    for (uint256 i = 0; i < _transfers.length; i++) {
      _transfer(_transfers[i].from, _transfers[i].to, _transfers[i].creditAmount, _key);
    }
    emit BatchTransfer(_batchId);
  }

  /**
   * @notice Transfer credits, a fee is taken. Can only be called by admin wallet
   * @param _from address
   * @param  _to address
   * @param  _creditAmount uint256 - amount to transfer
   * @param _key string - fee component key, deciding what fee calculation is made
   */
  function _transfer(
    address _from,
    address _to,
    uint256 _creditAmount,
    bytes32 _key
  ) private {
    require(creditBalance(_from) >= _creditAmount, 'Not enough credits.');
    require(feeComponents[_key].code != 0, 'Key does not exist.');

    uint256 earnings;
    uint256 fee;
    if (feeComponents[_key].code == PERCENTAGE_RATE) {
      (earnings, fee) = _calcPercentageRateFee(
        _creditAmount,
        feeComponents[_key].value
      );
    } else if (feeComponents[_key].code == FIXED_RATE) {
      (earnings, fee) = _calcFixedRateFee(
        _creditAmount,
        feeComponents[_key].value
      );
    }

    _removeCredits(_from, _creditAmount);
    _addRevenue(fee);
    _addCredits(_to, earnings);

    emit Transfer(_from, _to, _creditAmount, fee, creditBalance(_from), creditBalance(_to), _key);
  }

  /**
   * @notice Calculates the earnings and fees of fixed rate
   * @param _amount uint256
   * @param _fixedRate uint256
   */
  function _calcFixedRateFee(uint256 _amount, uint256 _fixedRate)
    private
    pure
    returns (uint256, uint256)
  {
    if (_fixedRate > _amount) {
      return (0, _amount);
    }

    return (_amount - _fixedRate, _fixedRate);
  }

  /**
   * @notice Calculates the earnings and fees of percentage rate,
   * @param _amount uint256
   * @param _feePercentage uint256, 0 - 1000 representing 0.0 - 100.0 %
   */
  function _calcPercentageRateFee(uint256 _amount, uint256 _feePercentage)
    private
    pure
    returns (uint256, uint256)
  {
    if (_feePercentage == 0) {
      return (_amount, 0);
    }

    uint256 fee = (_amount * _feePercentage + 500) / 1000;

    // Xeenon will take a minimum fee of 1 credit for the transaction
    if (fee == 0) {
      fee = 1;
    }

    return (_amount - fee, fee);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import './AccessControl.sol';

abstract contract CreditLedger is AccessControl {
  using SafeERC20 for IERC20;

  uint256 private constant creditsConversion = 1E16;

  // Stable coin used
  IERC20 public immutable acceptedToken;

  uint256 private accumulatedRevenue;
  address private treasuryReceiver;

  mapping(address => uint256) private creditBalances;

  constructor(
    IERC20 _acceptedToken,
    address _admin,
    address _treasuryReceiver
  ) AccessControl(_admin) {
    acceptedToken = _acceptedToken;
    treasuryReceiver = _treasuryReceiver;
  }

  function _addRevenue(uint256 _credits) internal {
    accumulatedRevenue = accumulatedRevenue + _credits;
  }

  /**
   * @notice Withdraws all the revenue. Can only be called by admin wallet.
   */
  function withdrawRevenue() external onlyAdmin {
    uint256 withdrawAmount = accumulatedRevenue * creditsConversion;
    accumulatedRevenue = 0;
    acceptedToken.safeTransfer(treasuryReceiver, withdrawAmount);
  }

  function getAccumulatedRevenue() external view returns (uint256) {
    return accumulatedRevenue;
  }

  function getTreasuryReceiver() external view onlyOwner returns (address) {
    return treasuryReceiver;
  }

  function _addCredits(address _user, uint256 _credits) internal {
    creditBalances[_user] = creditBalances[_user] + _credits;
  }

  function _removeCredits(address _user, uint256 _credits) internal {
    require(creditBalances[_user] >= _credits, "Can't have negative credits.");
    creditBalances[_user] = creditBalances[_user] - _credits;
  }

  function creditBalance(address _user) public view returns (uint256) {
    return creditBalances[_user];
  }

  function changeTreasuryReceiver(address _newTreasuryReceiver)
    external
    onlyOwner
  {
    require(_newTreasuryReceiver != address(0), 'address is the zero address');
    treasuryReceiver = _newTreasuryReceiver;
  }

  function convertToCredits(uint256 _stableCoins)
    public
    pure
    returns (uint256)
  {
    return _stableCoins / creditsConversion;
  }

  function convertFromCredits(uint256 _credits) public pure returns (uint256) {
    return _credits * creditsConversion;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './interfaces/IAccessControl.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';
import './Admin.sol';

/**
 * @dev This is a modified version of @openzeppelin's AccessControl, giving all control to Admin
 * address and have the ability to clear all current role accounts. Contract module that allows
 * children to implement role-based access control mechanisms. This is a lightweight version that
 * doesn't allow enumerating role members except through off-chain means by accessing the contract
 * event logs.
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
 * {revokeRole} functions. Each role is associated with admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165, Admin {
  using EnumerableSet for EnumerableSet.AddressSet;

  bytes32 public constant FREEZE = keccak256('FREEZE');
  bytes32 public constant TRANSFER = keccak256('TRANSFER');

  struct RoleData {
    mapping(address => bool) members;
  }

  mapping(bytes32 => RoleData) private roles;

  mapping(bytes32 => EnumerableSet.AddressSet) private members;

  constructor(address _admin) Admin(_admin) {}

  /**
   * @dev Modifier that checks that an account has a specific _role. Reverts
   * with a standardized message including the required _role.
   *
   * The format of the revert reason is given by the following regular expression:
   *
   *  /^AccessControl: account (0x[0-9a-f]{40}) is missing _role (0x[0-9a-f]{64})$/
   *
   * _Available since v4.1._
   */
  modifier onlyRole(bytes32 _role) {
    _checkRole(_role);
    _;
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 _interfaceId)
    public
    view
    virtual
    override
    returns (bool)
  {
    return
      _interfaceId == type(IAccessControl).interfaceId ||
      super.supportsInterface(_interfaceId);
  }

  /**
   * @dev Returns `true` if `_account` has been granted `_role`.
   */
  function hasRole(bytes32 _role, address _account)
    public
    view
    virtual
    override
    returns (bool)
  {
    return roles[_role].members[_account];
  }

  /**
   * @dev Revert with a standard message if `_msgSender()` is missing `_role`.
   * Overriding this function changes the behavior of the {onlyRole} modifier.
   *
   * Format of the revert message is described in {_checkRole}.
   *
   * _Available since v4.6._
   */
  function _checkRole(bytes32 _role) internal view virtual {
    _checkRole(_role, _msgSender());
  }

  /**
   * @dev Revert with a standard message if `_account` is missing `_role`.
   *
   * The format of the revert reason is given by the following regular expression:
   *
   *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
   */
  function _checkRole(bytes32 _role, address _account) internal view virtual {
    if (!hasRole(_role, _account)) {
      revert(
        string(
          abi.encodePacked(
            'AccessControl: account ',
            Strings.toHexString(_account),
            ' is missing role ',
            Strings.toHexString(uint256(_role), 32)
          )
        )
      );
    }
  }

  /**
   * @dev Revokes `_role` from the calling account.
   *
   * Roles are often managed via {grantRole} and {revokeRole}: this function's
   * purpose is to provide a mechanism for accounts to lose their privileges
   * if they are compromised (such as when a trusted device is misplaced).
   *
   * If the calling account had been revoked `_role`, emits a {RoleRevoked}
   * event.
   *
   * Requirements:
   *
   * - the caller must be `account`.
   *
   * May emit a {RoleRevoked} event.
   */
  function renounceRole(bytes32 _role, address _account)
    public
    virtual
    override
  {
    require(
      _account == _msgSender(),
      'AccessControl: can only renounce roles for self'
    );

    _revokeRole(_role, _account);
  }

  /**
   * @dev Grants `_role` to `_account`.
   *
   * Internal function without access restriction.
   *
   * May emit a {RoleGranted} event.
   */
  function _grantRole(bytes32 _role, address _account) internal virtual {
    if (!hasRole(_role, _account)) {
      roles[_role].members[_account] = true;
      members[_role].add(_account);
      emit RoleGranted(_role, _account, _msgSender());
    }
  }

  /**
   * @dev Revokes `_role` from `_account`.
   *
   * Internal function without access restriction.
   *
   * May emit a {RoleRevoked} event.
   */
  function _revokeRole(bytes32 _role, address _account) internal virtual {
    if (hasRole(_role, _account)) {
      roles[_role].members[_account] = false;
      members[_role].remove(_account);
      emit RoleRevoked(_role, _account, _msgSender());
    }
  }

  /**
   * @dev Grants TRANSFER role to `_account`.
   *
   * If `account` had not been already granted TRANSFER ROLE, emits a {RoleGranted}
   * event.
   *
   * May emit a {RoleGranted} event.
   */
  function grantTransferRole(address _account) external virtual onlyAdmin {
    _grantRole(TRANSFER, _account);
  }

  /**
   * @dev Revoke TRANSFER role to `_account`.
   *
   * If `account` had not been already granted TRANSFER ROLE, emits a {RoleRevoked}
   * event.
   *
   * May emit a {RoleRevoked} event.
   */
  function revokeTransferRole(address _account) external virtual onlyAdmin {
    _revokeTransferRole(_account);
  }

  function _revokeTransferRole(address _account) private {
    _revokeRole(TRANSFER, _account);
  }

  /**
   * @dev Revokes TRANSFER role to everyone who has.
   */
  function clearTransferAccounts() external virtual onlyAdmin {
    uint256 length = members[TRANSFER].length();

    for (uint256 i = length; i > 0; i--) {
      _revokeTransferRole(members[TRANSFER].at(i - 1));
    }
  }

  /**
   * @dev Grants FREEZE role to `_account`.
   *
   * If `account` had not been already granted FREEZE ROLE, emits a {RoleGranted}
   * event.
   *
   * May emit a {RoleGranted} event.
   */
  function grantFreezeRole(address _account) external virtual onlyAdmin {
    _grantRole(FREEZE, _account);
  }

  /**
   * @dev Revoke FREEZE role to `_account`.
   *
   * If `account` had not been already granted FREEZE ROLE, emits a {RoleRevoked}
   * event.
   *
   * May emit a {RoleRevoked} event.
   */
  function revokeFreezeRole(address _account) external virtual onlyAdmin {
    _revokeFreezeRole(_account);
  }

  function _revokeFreezeRole(address _account) private {
    _revokeRole(FREEZE, _account);
  }

  /**
   * @dev Revokes FREEZE role to everyone who has.
   */
  function clearFreezeAccounts() external virtual onlyAdmin {
    uint256 length = members[FREEZE].length();

    for (uint256 i = length; i > 0; i--) {
      _revokeFreezeRole(members[FREEZE].at(i - 1));
    }
  }

  /**
   * @dev Get all account with role `_role`.
   */
  function getRoleAccounts(bytes32 _role) external view onlyAdmin returns (address[] memory) {
    return members[_role].values();
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an credit admin) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyAdmin`, which can be applied to your functions to restrict their use to
 * the admin.
 *
 * Needs a address at deployment to set admin. Then only the owner of the contract can
 * change the admin.
 */
abstract contract Admin is Ownable {
  address private admin;

  event AdminChanged(address indexed previousAdmin, address indexed newAdmin);

  /**
   * @notice Initializes the contract setting the deployer as the initial admin.
   */
  constructor(address _admin) {
    _changeAdmin(_admin);
  }

  /**
   * @notice Returns the address of the current admin.
   */
  function getAdmin() public view virtual returns (address) {
    return admin;
  }

  /**
   * @notice Throws if called by any account other than the admin.
   */
  modifier onlyAdmin() {
    _checkAdmin();
    _;
  }

  /**
   * @notice Throws if the sender is not the admin.
   */
  function _checkAdmin() internal view virtual {
    require(admin == _msgSender(), 'Caller is not the admin');
  }

  /**
   * @notice Changes admin of the contract to a new account (`_newAdmin`).
   * Can only be called by the current owner.
   */
  function changeAdmin(address _newAdmin) public virtual onlyOwner {
    require(_newAdmin != address(0), 'New admin is the zero address');
    _changeAdmin(_newAdmin);
  }

  /**
   * @notice Changes  of the contract to a new account (`_newAdmin`).
   * Internal function without access restriction.
   */
  function _changeAdmin(address _newAdmin) internal virtual {
    address oldAdmin = admin;
    admin = _newAdmin;
    emit AdminChanged(oldAdmin, admin);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
  /**
   * @dev Emitted when `account` is granted `role`.
   *
   * `sender` is the account that originated the contract call, an admin role
   * bearer except when using {AccessControl-_setupRole}.
   */
  event RoleGranted(
    bytes32 indexed role,
    address indexed account,
    address indexed sender
  );

  /**
   * @dev Emitted when `account` is revoked `role`.
   *
   * `sender` is the account that originated the contract call:
   *   - if using `revokeRole`, it is the admin role bearer
   *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
   */
  event RoleRevoked(
    bytes32 indexed role,
    address indexed account,
    address indexed sender
  );

  /**
   * @dev Returns `true` if `account` has been granted `role`.
   */
  function hasRole(bytes32 role, address account) external view returns (bool);

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}