// SPDX-License-Identifier: BUSL-1.1
// See bluejay.finance/license
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

import "./interfaces/ILoanPool.sol";
import "./interfaces/ICreditLineBase.sol";
import "./interfaces/ILoanPoolFactory.sol";

contract LoanPoolFactory is ILoanPoolFactory, AccessControl {
  bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

  /// @notice Address of the fee recipient
  address public override feeRecipient;

  /// @notice Address of the loan pool template
  address public override loanPoolTemplate;

  /// @notice Credit line template that can be used with the factory
  mapping(address => bool) public override isCreditLineTemplate;

  /// @notice Fees for a particular fee tier, in WAD
  mapping(uint256 => uint256) public override feesForTier;

  /// @notice Fee tier for a particular asset
  mapping(address => uint256) public override feesTierForAsset;

  /// @notice Is a loan pool deployed by this factory contract
  mapping(address => bool) public override loanPoolDeployed;

  /// @notice Checks that the credit line template is registered
  /// @param template Address of the credit line template
  modifier onlyCreditLineTemplate(address template) {
    if (!isCreditLineTemplate[template])
      revert CreditLineTemplateNotRegistered();
    _;
  }

  /// @notice Constructor of the factory
  /// @param _feeRecipient Address of the fee recipient
  /// @param _loanPoolTemplate Address of the loan pool template
  /// @param _defaultFees Fees for the default fee tier
  constructor(
    address _feeRecipient,
    address _loanPoolTemplate,
    uint256 _defaultFees
  ) {
    feeRecipient = _feeRecipient;
    loanPoolTemplate = _loanPoolTemplate;
    feesForTier[0] = _defaultFees;
    _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    _setupRole(MANAGER_ROLE, msg.sender);
  }

  // =============================== PUBLIC FUNCTIONS =================================

  /// @notice Creates a new loan pool
  /// @param creditLineTemplate Address of the credit line template
  /// @param fundingAsset Address of the asset used for the loan
  /// @param borrower Address of the borrower
  /// @param _uints Array of values to initialize the loan, see params for _createPool
  /// @return loanPool Address of the loan pool
  /// @return creditLine Address of the credit line
  function createPool(
    address creditLineTemplate,
    address fundingAsset,
    address borrower,
    uint256[10] calldata _uints
  ) public override returns (ILoanPool loanPool, ICreditLineBase creditLine) {
    uint256 fee = feesOnAsset(fundingAsset);
    (loanPool, creditLine) = _createPool(
      creditLineTemplate,
      fundingAsset,
      borrower,
      [
        _uints[0],
        _uints[1],
        _uints[2],
        _uints[3],
        _uints[4],
        _uints[5],
        _uints[6],
        _uints[7],
        _uints[8],
        _uints[9],
        fee
      ]
    );
  }

  // =============================== MANAGERS FUNCTIONS =================================

  /// @notice Creates a new loan pool, with a custom fee, in WAD
  /// @param creditLineTemplate Address of the credit line template
  /// @param fundingAsset Address of the asset used for the loan
  /// @param borrower Address of the borrower
  /// @param _uints Array of values to initialize the loan, see params for _createPool
  /// @return loanPool Address of the loan pool
  /// @return creditLine Address of the credit line
  function createCustomPool(
    address creditLineTemplate,
    address fundingAsset,
    address borrower,
    uint256[11] calldata _uints
  )
    public
    override
    onlyRole(MANAGER_ROLE)
    returns (ILoanPool loanPool, ICreditLineBase creditLine)
  {
    (loanPool, creditLine) = _createPool(
      creditLineTemplate,
      fundingAsset,
      borrower,
      _uints
    );
  }

  // =============================== INTERNAL FUNCTIONS =================================

  /// @notice Internal function to create a new loan pool
  /// @param creditLineTemplate Address of the credit line template
  /// @param fundingAsset Address of the asset used for the loan
  /// @param borrower Address of the borrower
  /// @param _uints Array of values to initialize the loan
  // _uints[0] _maxLimit Maximum amount of assets that can be borrowed, in asset's decimals
  // _uints[1] _interestApr Annual interest rate, in WAD
  // _uints[2] _paymentPeriod Length of each payment period, in seconds
  // _uints[3] _gracePeriod Length of the grace period (late fees is not applied), in seconds
  // _uints[4] _lateFeeApr Additional annual interest rate applied on late payments, in WAD
  // _uints[5] _loanTenureInPeriods Number of periods before the loan is due, in wei
  // _uints[6] _fundingStart Timestamp of the start of the funding period, in unix epoch time
  // _uints[7] _fundingPeriod Length of the funding period, in seconds
  // _uints[8] _minFundingRequired Minimum amount of funding required, in asset's decimals
  // _uints[9] _drawdownPeriod Length of the drawdown period before refund occurs, in seconds
  // _uints[10] _fee Fee for the loan, in WAD
  /// @return loanPool Address of the loan pool
  /// @return creditLine Address of the credit line
  function _createPool(
    address creditLineTemplate,
    address fundingAsset,
    address borrower,
    uint256[11] memory _uints
  )
    internal
    onlyCreditLineTemplate(creditLineTemplate)
    returns (ILoanPool loanPool, ICreditLineBase creditLine)
  {
    creditLine = ICreditLineBase(Clones.clone(creditLineTemplate));
    loanPool = ILoanPool(Clones.clone(loanPoolTemplate));
    loanPool.initialize(
      creditLine,
      IERC20(fundingAsset),
      borrower,
      feeRecipient,
      _uints
    );
    loanPoolDeployed[address(loanPool)] = true;
    emit LoanPoolCreated(
      address(loanPool),
      borrower,
      fundingAsset,
      creditLineTemplate,
      address(creditLine),
      _uints[0],
      _uints[10]
    );
  }

  // =============================== ADMIN FUNCTIONS =================================

  /// @notice Add a new credit line template that determines the loan term
  /// @param _creditLine Address of the credit line template
  function addCreditLine(address _creditLine)
    public
    override
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    isCreditLineTemplate[_creditLine] = true;
    emit UpdateCreditLineTemplate(_creditLine, true);
  }

  /// @notice Remove a credit line template
  /// @param _creditLine Address of the credit line template
  function removeCreditLine(address _creditLine)
    public
    override
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    isCreditLineTemplate[_creditLine] = false;
    emit UpdateCreditLineTemplate(_creditLine, false);
  }

  /// @notice Set the fees for a given tier of assets
  /// @dev Tier 0 is the default for assets that did not get tagged explicitly
  /// @param tier Tier of the asset
  /// @param fee Fees, in WAD
  function setFeeTier(uint256 tier, uint256 fee)
    public
    override
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    feesForTier[tier] = fee;
    emit UpdateFeeTier(tier, fee);
  }

  /// @notice Set the fee tier for a given asset
  /// @param asset Address of the asset
  /// @param tier Tier of the asset
  function setAssetFeeTier(address asset, uint256 tier)
    public
    override
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    feesTierForAsset[asset] = tier;
    emit UpdateAssetFeeTier(asset, tier);
  }

  /// @notice Set the fee recipient
  /// @param _feeRecipient Address of the fee recipient
  function setFeeRecipient(address _feeRecipient)
    public
    override
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    feeRecipient = _feeRecipient;
    emit UpdateFeeRecipient(_feeRecipient);
  }

  // =============================== VIEW FUNCTIONS =================================

  /// @notice Get the fees applied on the loan for a given asset
  /// @param asset Address of the asset
  /// @return fee Fees, in WAD
  function feesOnAsset(address asset)
    public
    view
    override
    returns (uint256 fee)
  {
    fee = feesForTier[feesTierForAsset[asset]];
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

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
        _checkRole(role, _msgSender());
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
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
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
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./ICreditLineBase.sol";

interface ILoanPool {
  /// @notice Amount is zero
  error ZeroAmount();

  /// @notice Funding period has not started
  error FundingPeriodNotStarted();

  /// @notice Funding period has ended
  error FundingPeriodEnded();

  /// @notice Funding period has not ended
  error FundingPeriodNotEnded();

  /// @notice Minimum amount of funds has been raised
  error MinimumFundingReached();

  /// @notice Minimum amount of funds has not been raised
  error MinimumFundingNotReached();

  /// @notice Drawdown period has not ended
  error DrawdownPeriodNotEnded();

  /// @notice Drawdown period has ended
  error DrawdownPeriodEnded();

  /// @notice Loan is not in funding state
  error NotFundingState();

  /// @notice Insufficient balance for withdraw
  error InsufficientBalance();

  /// @notice Tokens cannot be transferred
  error TransferDisabled();

  /// @notice Loan is not in refund state
  error NotRefundState();

  /// @notice Funds have been deposited into the loan pool
  /// @param lender Address of the lender
  /// @param recipient Address where loan token is credited to
  /// @param amount Amount of funds deposited
  event Fund(address indexed lender, address indexed recipient, uint256 amount);

  /// @notice Lenders are allowed to withdraw their funds from the loan pool
  event Refunded();

  /// @notice Borrower has drawndown on the loan
  event Drawndown(address indexed borrower, uint256 amount);

  /// @notice Fees are collected from the loan pool
  /// @param borrower Address of borrower
  /// @param recipient Address where fees are credited to
  /// @param amount Amount of fees collected
  event FeesCollected(
    address indexed borrower,
    address indexed recipient,
    uint256 amount
  );

  /// @notice Funds are beind refunded to lender
  /// @param lender Address of the lender
  /// @param recipient Address where refunds are being sent
  /// @param amount Amount of funds refunded
  event Refund(
    address indexed lender,
    address indexed recipient,
    uint256 amount
  );

  /// @notice Borrower repays funds to the loan pool
  /// @param payer Address of the payer
  /// @param amount Amount of funds repaid
  event Repay(address indexed payer, uint256 amount);

  /// @notice Additional payments was refunded to the borrower
  /// @param payer Address of the payer
  /// @param amount Amount of funds refunded
  event RefundAdditionalPayment(address indexed payer, uint256 amount);

  /// @notice Funds are being withdrawn from the loan pool as lender
  /// after funds are repaid by the borrower
  /// @param lender Address of the lender
  /// @param recipient Address where funds are being sent
  /// @param amount Amount of funds withdrawn
  event Withdraw(
    address indexed lender,
    address indexed recipient,
    uint256 amount
  );

  function initialize(
    ICreditLineBase _creditLine,
    IERC20 _fundingAsset,
    address _borrower,
    address _feeRecipient,
    uint256[11] calldata _uints // collapsing because of stack too deep
  ) external;

  function creditLine() external view returns (ICreditLineBase);

  function fundingAsset() external view returns (IERC20);

  function borrower() external view returns (address);

  function deployer() external view returns (address);

  function feeRecipient() external view returns (address);

  function fundingStart() external view returns (uint256);

  function fundingEnd() external view returns (uint256);

  function minFundingRequired() external view returns (uint256);

  function drawdownPeriod() external view returns (uint256);

  function fees() external view returns (uint256);

  function repayments(address) external view returns (uint256);

  function fund(uint256 amount, address recipient) external;

  function refundMinimumNotMet() external;

  function refundInactiveBorrower() external;

  function refund(address recipient) external;

  function drawdown() external;

  function repay(uint256 amount) external;

  function withdraw(uint256 amount, address recipient) external;

  function balanceAvailable(address account)
    external
    view
    returns (uint256 balance);

  function shareOfPool(address account) external view returns (uint256 share);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ICreditLineBase {
  /// @notice State of the loan
  /// @param Funding loan is currently fundraising from lenders
  /// @param Refund funding failed, funds to be returned to lenders, terminal state
  /// @param Repayment loan has been drawndown and borrower is repaying the loan
  /// @param Repaid loan has been fully repaid by borrower, terminal state
  enum State {
    Funding,
    Refund,
    Repayment,
    Repaid
  }

  /// @notice When a function is executed under the wrong loan state
  /// @param expectedState State that the loan should be in for the function to execute
  /// @param currentState State that the loan is currently in
  error IncorrectState(State expectedState, State currentState);

  /// @notice Funding exceeds the max limit
  error MaxLimitExceeded();

  /// @notice Loan state of the credit line has been updated
  /// @param newState State of the loan after the update
  event LoanStateUpdate(State indexed newState);

  /// @notice Repayment has been made towards loan
  /// @param timestamp Timestamp of repayment
  /// @param amount Amount of repayment
  /// @param interestRepaid Payment towards interest
  /// @param principalRepaid Payment towards principal
  /// @param additionalRepayment Excess payments
  event Repayment(
    uint256 timestamp,
    uint256 amount,
    uint256 interestRepaid,
    uint256 principalRepaid,
    uint256 additionalRepayment
  );

  function maxLimit() external view returns (uint256);

  function interestApr() external view returns (uint256);

  function paymentPeriod() external view returns (uint256);

  function gracePeriod() external view returns (uint256);

  function lateFeeApr() external view returns (uint256);

  function principalBalance() external view returns (uint256);

  function interestBalance() external view returns (uint256);

  function totalPrincipalRepaid() external view returns (uint256);

  function totalInterestRepaid() external view returns (uint256);

  function additionalRepayment() external view returns (uint256);

  function lateInterestAccrued() external view returns (uint256);

  function interestAccruedAsOf() external view returns (uint256);

  function lastFullPaymentTime() external view returns (uint256);

  function minPaymentPerPeriod() external view returns (uint256);

  function loanStartTime() external view returns (uint256);

  function loanTenureInPeriods() external view returns (uint256);

  function loanState() external view returns (State);

  function initialize(
    uint256 _maxLimit,
    uint256 _interestApr,
    uint256 _paymentPeriod,
    uint256 _gracePeriod,
    uint256 _lateFeeApr,
    uint256 _loanTenureInPeriods
  ) external;

  function fund(uint256 amount) external;

  function drawdown() external returns (uint256 amount);

  function refund() external;

  function repay(uint256 amount)
    external
    returns (
      uint256 interestPayment,
      uint256 principalPayment,
      uint256 additionalBalancePayment
    );

  function allocatePayment(
    uint256 amount,
    uint256 interestOutstanding,
    uint256 principalOutstanding
  )
    external
    pure
    returns (
      uint256 interestPayment,
      uint256 principalPayment,
      uint256 additionalBalancePayment
    );

  function minPaymentForSchedule() external view returns (uint256 amount);

  function paymentDue() external view returns (uint256 amount);

  function minPaymentAtTimestamp(uint256 timestamp)
    external
    view
    returns (uint256 amount);

  function interestAccruedSinceLastAssessed()
    external
    view
    returns (
      uint256 interestOwed,
      uint256 lateInterestOwed,
      uint256 fullPeriodsElapsed
    );

  function interestAccruedAtTimestamp(uint256 timestamp)
    external
    view
    returns (
      uint256 interestOwed,
      uint256 lateInterestOwed,
      uint256 fullPeriodsElapsed
    );

  function interestOnBalance(uint256 timePeriod)
    external
    view
    returns (uint256 interestOwed);

  function lateInterestOnBalance(uint256 timePeriod)
    external
    view
    returns (uint256 interestOwed);

  function totalRepayments() external view returns (uint256 amount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./ILoanPool.sol";
import "./ICreditLineBase.sol";

interface ILoanPoolFactory {
  /// @notice Credit line template is not registered with the factory
  error CreditLineTemplateNotRegistered();

  /// @notice New loan pool has been created
  /// @param loanPool Address of the loan pool
  /// @param borrower Address of the borrower
  /// @param fundingAsset Address of the asset used for the loan
  /// @param creditLineTemplate Address of the template which loan terms
  /// @param creditLine Address of the credit line
  /// @param maxLimit Maximum amount of funds that can be raised
  /// @param fees Fees charged for the loan
  event LoanPoolCreated(
    address indexed loanPool,
    address indexed borrower,
    address indexed fundingAsset,
    address creditLineTemplate,
    address creditLine,
    uint256 maxLimit,
    uint256 fees
  );

  /// @notice Fee recipient has been updated
  /// @param feeRecipient Address of fee recipient
  event UpdateFeeRecipient(address indexed feeRecipient);

  /// @notice Fee tier of a particular asset has been updated
  /// @param asset Address of the asset
  /// @param tier Updated fee tier of the asset
  event UpdateAssetFeeTier(address indexed asset, uint256 indexed tier);

  /// @notice Updated fees for a fee tier
  /// @param tier Fee tier
  /// @param fees Fees for the fee tier
  event UpdateFeeTier(uint256 indexed tier, uint256 fees);

  /// @notice Credit line template has been registered or unregistered
  /// @param creditLineTemplate Address of the credit line template
  /// @param isRegistered If the template can be used in creating new loan pools
  event UpdateCreditLineTemplate(
    address indexed creditLineTemplate,
    bool indexed isRegistered
  );

  function createPool(
    address creditLineTemplate,
    address fundingAsset,
    address borrower,
    uint256[10] calldata _uints
  ) external returns (ILoanPool loanPool, ICreditLineBase creditLine);

  function createCustomPool(
    address creditLineTemplate,
    address fundingAsset,
    address borrower,
    uint256[11] calldata _uints
  ) external returns (ILoanPool loanPool, ICreditLineBase creditLine);

  function feeRecipient() external view returns (address);

  function loanPoolTemplate() external view returns (address);

  function isCreditLineTemplate(address template) external view returns (bool);

  function feesForTier(uint256 tier) external view returns (uint256);

  function feesTierForAsset(address asset) external view returns (uint256);

  function loanPoolDeployed(address) external view returns (bool);

  function feesOnAsset(address asset) external view returns (uint256 fee);

  function addCreditLine(address _creditLine) external;

  function removeCreditLine(address _creditLine) external;

  function setFeeTier(uint256 tier, uint256 fee) external;

  function setAssetFeeTier(address asset, uint256 tier) external;

  function setFeeRecipient(address _feeRecipient) external;
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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