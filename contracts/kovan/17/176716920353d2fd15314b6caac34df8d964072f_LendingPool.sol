// SPDX-License-Identifier: No License
/**
 * @title Vendor Lending Pool Implementation
 * @author 0xTaiga
 * The legend says that you'r pipi shrinks and boobs get saggy if you fork this contract.
 */
pragma solidity ^0.8.11;

import "./interfaces/IVendorOracle.sol";
import "./interfaces/ILendingPool.sol";
import "./interfaces/IFeesManager.sol";
import "./ERC20/SafeERC20.sol";
import "./interfaces/IPoolFactory.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract LendingPool is
    IStructs,
    ILendingPool,
    UUPSUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20 for IERC20;

    /* ========== ERRORS ========== */
    /// @notice Error for if a mint ratio of 0 is passed in
    error MintRatio0();
    /// @notice Error for if pool is closed
    error PoolClosed();
    /// @notice Error for if pool is active
    error PoolActive();
    /// @notice Error for if price is not valid
    error NotValidPrice();
    /// @notice Error for if not enough liquidity in pool
    error NotEnoughLiquidity();
    /// @notice Error for if balance is insufficient
    error InsufficientBalance();
    /// @notice Error for if address is not a pool
    error NotAPool();
    /// @notice Error for if address is different than lend token
    error DifferentLendToken();
    /// @notice Error for if address is different than collateral token
    error DifferentColToken();
    /// @notice Error for if owner addresses are different
    error DifferentPoolOwner();
    /// @notice Error for if expiry of a roll over pool is not long enough
    error ExpiryNotLongEnough();
    /// @notice Error for if a user has no debt
    error NoDebt();
    /// @notice Error for if user is trying to pay back more than the debt they have
    error DebtIsLess();
    /// @notice Error for if balance is not validated
    error TransferFailed();
    /// @notice Error for if user tries to interract with private pool
    error PrivatePool();
    /// @notice Error for if operations of this pool or potetntially all pools is stopped.
    error OperationsPaused();
    /// @notice Error for if lender paused borrowing.
    error BorrowingPaused();
    /// @notice Error for if Oracle not set.
    error OracleNotSet();
    /// @notice Error for if called by not owner
    error NotOwner();
    /// @notice Error for if illegal upgrade implementation
    error IllegalImplementation();
    /// @notice Error for if upgrades are not allowed at this time
    error UpgradeNotAllowed();
    /// @notice Error for if expiry is wrong
    error InvalidExpiry();

    /* ========== STATE VARIABLES ========== */
    uint256 public mintRatio;
    IERC20 public override colToken;
    IERC20 public override lendToken;
    uint256 public protocolFee; //bpt
    uint256 public protocolColFee; //bpt
    uint256 public totalFees;
    uint256 public totalBorrowed;
    address public owner;
    mapping(address => UserReport) public debt;
    uint256 public expiry;
    uint256 public disabledBorrow;
    uint256 public isPrivate;
    mapping(address => uint256) public borrowers;

    IVendorOracle public priceFeed;
    IPoolFactory public factory;
    IFeesManager public feeManager;
    address public treasury;

    /// @notice Initialize the pool with all the user provided settings
    /// @param data See the IStructs for the layout
    function initialize(Data calldata data) external initializer {
        mintRatio = data.mintRatio;
        if (mintRatio <= 0) revert MintRatio0();
        __UUPSUpgradeable_init();
        owner = data.deployer;
        colToken = IERC20(data.colToken);
        lendToken = IERC20(data.lendToken);
        factory = IPoolFactory(msg.sender);
        priceFeed = IVendorOracle(data.oracle);
        feeManager = IFeesManager(data.feesManager);
        treasury = factory.treasury();
        protocolFee = data.protocolFee;
        protocolColFee = data.protocolColFee;
        expiry = data.expiry;
        if (data.borrowers.length > 0) {
            isPrivate = 1;
            for (uint256 j = 0; j != data.borrowers.length; ++j) {
                borrowers[data.borrowers[j]] = 1;
            }
        }
    }

    /* ========== PUBLIC FUNCTIONS ========== */
    ///@notice Deposit the funds you would like to lend. Prior approval of lend token is required
    ///@param _depositAmount Amount of lend token to deposit into the pool
    function deposit(uint256 _depositAmount) external nonReentrant {
        onlyOwner();
        if (factory.isPaused(address(this))) revert OperationsPaused();
        _pullTokensFrom(msg.sender, lendToken, _depositAmount);
    }

    ///@notice Withdraw the lend token from the pool
    ///@param _amount Amount of lend token to withdraw from the pool
    function withdraw(uint256 _amount) public nonReentrant {
        onlyOwner();
        if (factory.isPaused(address(this))) revert OperationsPaused();
        if (
            lendToken.balanceOf(address(this)) <
            _amount + ((totalFees * protocolFee) / 1000000)
        ) revert InsufficientBalance();
        if (block.timestamp > expiry) revert PoolClosed();
        _safeTransfer(lendToken, msg.sender, _amount);
    }

    ///@notice Borrow on behalf of a wallet. Usefull on rollovers between pools deployed by two different lenders
    ///@param _borrower User that will need to repay the loan. Collateral of the the function caller is used
    ///@param _colDepositAmount Amount of col token user want to deposit as collateral
    function borrowOnBehalfOf(address _borrower, uint256 _colDepositAmount)
        public
        nonReentrant
    {
        if (disabledBorrow == 1) revert BorrowingPaused();
        if (factory.isPaused(address(this))) revert OperationsPaused();
        if (!_isValidPrice()) revert NotValidPrice();
        if (block.timestamp > expiry) revert PoolClosed();
        if (isPrivate == 1 && borrowers[msg.sender] == 0) revert PrivatePool();

        UserReport memory userReport = debt[_borrower];
        uint256 rawPayoutAmount = _computePayoutAmount(
            _colDepositAmount,
            mintRatio
        );

        if (!factory.pools(msg.sender)) {
            if (lendToken.balanceOf(address(this)) < rawPayoutAmount)
                revert NotEnoughLiquidity();

            _safeTransfer(lendToken, _borrower, rawPayoutAmount);
        }

        userReport.borrowAmount += rawPayoutAmount;
        uint256 fee = feeManager.getFee(
            address(this),
            rawPayoutAmount
        );
        userReport.totalFees += fee;
        totalFees += fee;
        _pullTokensFrom(msg.sender, colToken, _colDepositAmount);
        userReport.colAmount += _colDepositAmount;

        debt[_borrower] = userReport;
        totalBorrowed += rawPayoutAmount;
        emit Borrow(_borrower, _colDepositAmount);
    }

    ///@notice Rollover loan into a pool that has been deployed by the same lender as the original one
    ///@param _newPool Address of the destination pool
    function rollOver(address _newPool) external nonReentrant {
        if (factory.isPaused(address(this))) revert OperationsPaused();
        UserReport memory userReport = debt[msg.sender];
        if (block.timestamp > expiry) revert PoolClosed();
        if (userReport.borrowAmount <= 0) revert NoDebt();
        if (isPrivate == 1 && borrowers[msg.sender] == 0) revert PrivatePool();
        ILendingPool newPool = ILendingPool(_newPool);
        _validateNewPool(newPool);
        if (address(newPool.colToken()) != address(colToken))
            revert DifferentColToken();

        colToken.approve(_newPool, userReport.colAmount);
        if (newPool.mintRatio() <= mintRatio) {
            // Need to repay some loan
            uint256 diffToRepay = _computePayoutAmount(
                userReport.colAmount,
                mintRatio - newPool.mintRatio()
            );
            _pullTokensFrom(
                msg.sender,
                lendToken,
                diffToRepay + userReport.totalFees
            );
            newPool.borrowOnBehalfOf(msg.sender, userReport.colAmount);
        } else {
            // Reimburse the borrower
            uint256 diffToReimburse = (userReport.colAmount *
                ((newPool.mintRatio() - mintRatio) / 1e18)) /
                (newPool.mintRatio() / 1e18);
            _pullTokensFrom(msg.sender, lendToken, userReport.totalFees);
            _safeTransfer(colToken, msg.sender, diffToReimburse);
            newPool.borrowOnBehalfOf(
                msg.sender,
                userReport.colAmount - diffToReimburse
            );
        }
        userReport.colAmount = 0;
        userReport.borrowAmount = 0; //Clean users debdt in current pool
        userReport.totalFees = 0;
        debt[msg.sender] = userReport;
    }

    ///@notice Rollover availiable lent funds into a new pool after expiry
    ///@param _newPool Address of the destination pool
    function lenderRollOver(address _newPool) external nonReentrant {
        onlyOwner();
        if (factory.isPaused(address(this))) revert OperationsPaused();
        if (block.timestamp <= expiry) revert PoolActive();
        _payVendorFees();
        _validateNewPool(ILendingPool(_newPool));
        _safeTransfer(lendToken, _newPool, lendToken.balanceOf(address(this)));
        _safeTransfer(colToken, msg.sender, colToken.balanceOf(address(this)));
    }

    ///@notice Repay the loan on behalf of a different wallet
    ///@param _borrower wallet whos loan is going to be repaid
    ///@param _repayAmount amount of lend token that will be repaid
    function repayOnBehalfOf(address _borrower, uint256 _repayAmount)
        external
        nonReentrant
    {
        if (factory.isPaused(address(this))) revert OperationsPaused();
        UserReport memory userReport = debt[_borrower];
        if (block.timestamp > expiry) revert PoolClosed();
        if (_repayAmount > userReport.borrowAmount + userReport.totalFees)
            revert DebtIsLess();
        if (userReport.borrowAmount <= 0) revert NoDebt();

        uint256 repayRemainder = _repayAmount;

        //Repay the fee first.
        _pullTokensFrom(msg.sender, lendToken, _repayAmount);
        if (repayRemainder <= userReport.totalFees) {
            userReport.totalFees -= repayRemainder;
            debt[_borrower] = userReport;
            return ();
        } else if (userReport.totalFees > 0) {
            repayRemainder -= userReport.totalFees;
            userReport.totalFees = 0;
        }

        userReport.borrowAmount -= repayRemainder;
        uint256 colReturnAmount = _computeReturnAmount(repayRemainder);

        userReport.colAmount -= colReturnAmount;
        debt[_borrower] = userReport;
        _safeTransfer(colToken, _borrower, colReturnAmount);
        totalBorrowed -= repayRemainder;
        emit Repay(_borrower, _repayAmount);
    }

    ///@notice Collect the interest, defaulted collateral and pay vendor fee
    function collect() external nonReentrant {
        onlyOwner();
        if (factory.isPaused(address(this))) revert OperationsPaused();
        if (block.timestamp <= expiry) revert PoolActive();
        // Send the protocol fee to treasury
        _payVendorFees();

        // Send premium to lender
        _safeTransfer(
            lendToken,
            msg.sender,
            lendToken.balanceOf(address(this))
        );
        _safeTransfer(colToken, msg.sender, colToken.balanceOf(address(this)));
    }

    /* ========== PRIVATE FUNCTIONS ========== */
    ///@notice Make sure new pool can be rolled into
    function _validateNewPool(ILendingPool _pool) private view {
        if (!factory.pools(address(_pool))) revert NotAPool();

        if (address(_pool.lendToken()) != address(lendToken))
            revert DifferentLendToken();

        if (_pool.owner() != owner) revert DifferentPoolOwner();

        if (_pool.expiry() <= expiry) revert ExpiryNotLongEnough();
    }

    ///@notice Pay the outstanding vendor fee. Triggered on lender rollover and collect
    function _payVendorFees() private {
        uint256 feeDue = (totalFees * protocolFee) / 1000000;
        _safeTransfer(lendToken, treasury, feeDue);
        _safeTransfer(
            colToken,
            treasury,
            (colToken.balanceOf(address(this)) * protocolColFee) / 1000000
        );
        totalFees = 0;
    }

    ///@notice Compute the amount of lend tokesn to send given collateral deposited.
    ///@param _colDepositAmount in collateral token decimals
    ///@param _mintRatio useful on rollowver payout calculation
    ///@return Lend token amount in lend decimals
    function _computePayoutAmount(uint256 _colDepositAmount, uint256 _mintRatio)
        private
        view
        returns (uint256)
    {
        return
            (_colDepositAmount * _mintRatio * (10**lendToken.decimals())) /
            (10**colToken.decimals()) /
            1e18;
    }

    ///@notice Compute the amount of collateral to return given repayment amount. Does not account fees.
    ///@param _repayAmount in lend token decimals
    ///@return Collateral amount in collateral decimals
    function _computeReturnAmount(uint256 _repayAmount)
        private
        view
        returns (uint256)
    {
        return
            (_repayAmount * 1e18 * (10**colToken.decimals())) /
            (10**lendToken.decimals()) /
            mintRatio;
    }

    ///@notice Check if the borrowing is enables in this pool based on the oracle
    function _isValidPrice() private view returns (bool) {
        if (address(priceFeed) == address(0)) revert OracleNotSet();
        int256 priceLend = priceFeed.getPriceUSD(address(lendToken));
        int256 priceCol = priceFeed.getPriceUSD(address(colToken));
        if (priceLend != -1 && priceCol != -1) {
            return (priceCol > ((int256(mintRatio) * priceLend) / 1e18));
        }
        return true;
    }

    /* ========== SETTERS ========== */
    ///@notice Updates fees for pool
    ///@param _feeRate Fees amount that the lender charges
    ///@param _type Type of the fee chrged: 1 constant, 2 annualized
    function setFeeRates(uint256 _feeRate, uint256 _type) external {
        onlyOwner();
        feeManager.setPoolFees(address(this), _feeRate, _type);
    }

    function extendExpiry(uint256 _newDate) external {
        onlyOwner();
        if (!factory.allowUpgrade()) revert UpgradeNotAllowed(); //Only allow extension when we allow upgrade.
        if (_newDate <= expiry || _newDate > block.timestamp + 3 days)
            revert InvalidExpiry();
        expiry = _newDate;
        emit UpdateExpiry(_newDate);
    }

    function flipBorrow() external {
        onlyOwner();
        disabledBorrow = disabledBorrow == 1 ? 0 : 1;
    }

    function addBorrower(address _newBorrower) external {
        onlyOwner();
        borrowers[_newBorrower] = 1;
        emit AddBorrower(_newBorrower);
    }

    /* ========== UTILITY ========== */
    ///@notice Contract version for history
    ///@return Contract version
    function version() external pure override returns (uint256) {
        return 1;
    }

    ///@notice Pre-upgrade checks
    function _authorizeUpgrade(address newImplementation)
        internal
        view
        override
    {
        onlyOwner();
        if (
            newImplementation != factory.poolImplementationAddress() &&
            newImplementation != factory.rollBackImplementation()
        ) revert IllegalImplementation();
        if (!factory.allowUpgrade()) revert UpgradeNotAllowed();
    }

    ///@notice Pull the tokens from wallet and ensure balance increase
    ///@param sender Wallet that will send the tokens to Vendor
    ///@param token ERC20 to send
    ///@param amount Amount of token to send
    function _pullTokensFrom(
        address sender,
        IERC20 token,
        uint256 amount
    ) private {
        uint256 initialBalance = token.balanceOf(address(this));
        token.safeTransferFrom(sender, address(this), amount);
        if (token.balanceOf(address(this)) != initialBalance + amount)
            revert TransferFailed();
    }

    ///@notice Transfer tokens with overflow protection
    ///@param _token ERC20 token to send
    ///@param _account Address of an account to send to
    ///@param _amount Ammount of _token to send
    function _safeTransfer(
        IERC20 _token,
        address _account,
        uint256 _amount
    ) private {
        uint256 bal = _token.balanceOf(address(this));
        if (bal < _amount) {
            _token.safeTransfer(_account, bal);
        } else {
            _token.safeTransfer(_account, _amount);
        }
    }

    function onlyOwner() private view {
        if (msg.sender != owner) revert NotOwner();
    }

    function transferOwnership(address _owner) external {
        onlyOwner();
        owner = _owner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IVendorOracle {
    function getPriceUSD(address base) external view returns (int256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../ERC20/IERC20.sol";
import "./IStructs.sol";

interface ILendingPool is IStructs {
    struct UserReport {
        uint256 borrowAmount;
        uint256 colAmount;
        uint256 totalFees;
    }

    event Borrow(address borrower, uint256 colDepositAmount);
    event Repay(address borrower, uint256 repayAmount);
    event UpdateExpiry(uint256 newExpiry);
    event AddBorrower(address newBorrower);

    function initialize(Data calldata data) external;

    function version() external pure returns (uint256);

    function mintRatio() external view returns (uint256);

    function lendToken() external view returns (IERC20);

    function colToken() external view returns (IERC20);

    function expiry() external view returns (uint256);

    function borrowOnBehalfOf(address _borrower, uint256 _colDepositAmount)
        external;

    function owner() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IFeesManager {
    function getFee(
        address _pool,
        uint256 _rawPayoutAmount
    ) external view returns (uint256);

    function setPoolFees(address _pool, uint256 _feeRate, uint256 _type) external;

    function getCurrentRate(
        address _pool
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "../utils/Address.sol";

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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
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
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) - value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
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

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IPoolFactory {
    function pools(address _pool) external view returns (bool);

    function treasury() external view returns (address);

    function poolImplementationAddress() external view returns (address);

    function rollBackImplementation() external view returns (address);

    function allowUpgrade() external view returns (bool);

    function isPaused(address _pool) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
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
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
        __ERC1967Upgrade_init_unchained();
        __UUPSUpgradeable_init_unchained();
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: No License

pragma solidity ^0.8.0;

/**
 * @title Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function totalSupply() external view returns (uint256);

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool);

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../ERC20/IERC20.sol";

interface IStructs {
    struct Data {
        address deployer;
        uint256 mintRatio;
        address colToken;
        address lendToken;
        uint256 expiry;
        address[] borrowers;
        uint256 protocolFee;
        uint256 protocolColFee;
        address feesManager;
        address oracle;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
        __ERC1967Upgrade_init_unchained();
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlotUpgradeable.BooleanSlot storage rollbackTesting = StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            _functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}