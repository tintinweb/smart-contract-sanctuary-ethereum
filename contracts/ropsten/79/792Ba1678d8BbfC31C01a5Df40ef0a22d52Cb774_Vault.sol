// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "./interfaces/IOracle.sol";
import "./interfaces/IVaultConfig.sol";
import "./interfaces/IClerk.sol";

/// @title Vault - Lending Vault
contract Vault is OwnableUpgradeable, ReentrancyGuardUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    /// @dev Events
    event LogUpdateCollateralPrice(uint256 newPirce);
    event LogAccrue(uint256 amount);
    event LogAddCollateral(
        address indexed from,
        address indexed to,
        uint256 share
    );
    event LogBorrow(
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 part
    );

    /// @dev Constants
    uint256 private constant BPS_PRECISION = 1e4;
    uint256 private constant COLLATERAL_PRICE_PRECISION = 1e18;

    /// @dev Default configuration states.
    /// These configurations are expected to be the same amongs markets.
    IClerk public clerk;
    IERC20Upgradeable public spell;

    /// @dev Market configuration states.
    IERC20Upgradeable public collateral;
    IOracle public oracle;
    bytes public oracleData;

    /// @dev Global states of the market
    uint256 public totalCollateralShare;
    uint256 public totalDebtShare;
    uint256 public totalDebtValue;

    /// @dev User's states
    mapping(address => uint256) public userCollateralShare;
    mapping(address => uint256) public userDebtShare;

    /// @dev Price of collateral
    uint256 public collateralPrice;

    /// @dev Interest-related states
    uint256 public lastAccrueTime;

    /// @dev Protocol revenue
    uint256 public surplus;
    uint256 public liquidationFee;

    /// @dev Fee & Risk parameters
    IVaultConfig public marketConfig;

    /// @notice The constructor is only used for the initial master contract.
    /// Subsequent clones are initialised via `init`.
    function initialize(
        IClerk _clerk,
        IERC20Upgradeable _spell,
        IERC20Upgradeable _collateral,
        IVaultConfig _marketConfig,
        IOracle _oracle,
        bytes calldata _oracleData
    ) external initializer {
        OwnableUpgradeable.__Ownable_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();

        require(address(_clerk) != address(0), "clerk cannot be address(0)");
        require(address(_spell) != address(0), "spell cannot be address(0)");
        require(
            address(_collateral) != address(0),
            "collateral cannot be address(0)"
        );
        require(
            address(_marketConfig) != address(0),
            "marketConfig cannot be address(0)"
        );
        require(address(_oracle) != address(0), "oracle cannot be address(0)");

        clerk = _clerk;
        spell = _spell;
        collateral = _collateral;
        marketConfig = _marketConfig;
        oracle = _oracle;
        oracleData = _oracleData;
    }

    /// @notice Accrue interest and realized surplus.
    modifier accrue() {
        // Only accrue interest if there is time diff and there is a debt
        if (block.timestamp > lastAccrueTime) {
            // 1. Findout time diff between this block and update lastAccruedTime
            uint256 _timePast = block.timestamp - lastAccrueTime;
            lastAccrueTime = block.timestamp;

            // 2. If totalDebtValue > 0 then calculate interest
            if (totalDebtValue > 0) {
                // 3. Calculate interest
                uint256 _pendingInterest = (marketConfig.interestPerSecond(
                    address(this)
                ) *
                    totalDebtValue *
                    _timePast) / 1e18;
                totalDebtValue = totalDebtValue + _pendingInterest;

                // 4. Realized surplus
                surplus = surplus + _pendingInterest;

                emit LogAccrue(_pendingInterest);
            }
        }
        _;
    }

    /// @notice Modifier to check if the user is safe from liquidation at the end of function.
    modifier checkSafe() {
        _;
        require(_checkSafe(msg.sender, collateralPrice), "!safe");
    }

    /// @notice Return if true "_user" is safe from liquidation.
    /// @dev Beware of unaccrue interest. accrue is expected to be executed before _isSafe.
    /// @param _user The address to check if it is safe from liquidation.
    /// @param _collateralPrice The exchange rate. Used to cache the `exchangeRate` between calls.
    function _checkSafe(address _user, uint256 _collateralPrice)
        internal
        view
        returns (bool)
    {
        uint256 _collateralFactor = marketConfig.collateralFactor(
            address(this),
            _user
        );

        require(
            _collateralFactor <= 9500 && _collateralFactor >= 5000,
            "bad collateralFactor"
        );

        uint256 _userDebtShare = userDebtShare[_user];
        if (_userDebtShare == 0) return true;
        uint256 _userCollateralShare = userCollateralShare[_user];
        if (_userCollateralShare == 0) return false;

        return
            (clerk.toAmount(collateral, _userCollateralShare, false) *
                _collateralPrice *
                _collateralFactor) /
                BPS_PRECISION >=
            (_userDebtShare * totalDebtValue * COLLATERAL_PRICE_PRECISION) /
                totalDebtShare;
    }

    /// @notice check debt size after an execution
    modifier checkDebtSize() {
        _;
        if (debtShareToValue(userDebtShare[msg.sender]) == 0) return;
        require(
            debtShareToValue(userDebtShare[msg.sender]) >=
                marketConfig.minDebtSize(address(this)),
            "invalid debt size"
        );
    }

    /// @notice Perform actual add collateral
    /// @param _to The address of the user to get the collateral added
    /// @param _share The share of the collateral to be added
    function _addCollateral(address _to, uint256 _share) internal {
        require(
            clerk.balanceOf(collateral, msg.sender) -
                userCollateralShare[msg.sender] >=
                _share,
            "not enough balance to add collateral"
        );

        userCollateralShare[_to] = userCollateralShare[_to] + _share;
        uint256 _oldTotalCollateralShare = totalCollateralShare;
        totalCollateralShare = _oldTotalCollateralShare + _share;

        _addTokens(collateral, _to, _share);

        emit LogAddCollateral(msg.sender, _to, _share);
    }

    /// @notice Update collateral price and check slippage
    modifier updateCollateralPriceWithSlippageCheck(
        uint256 _minPrice,
        uint256 _maxPrice
    ) {
        (bool _update, uint256 _price) = updateCollateralPrice();
        require(_update, "bad price");
        require(_price >= _minPrice && _price <= _maxPrice, "slippage");
        _;
    }

    /// @notice Adds `collateral` from msg.sender to the account `to`.
    /// @param _to The receiver of the tokens.
    /// @param _amount The amount of collateral to be added to "_to".
    function addCollateral(address _to, uint256 _amount)
        public
        nonReentrant
        accrue
    {
        uint256 _share = clerk.toShare(collateral, _amount, false);
        _addCollateral(_to, _share);
    }

    /// @dev Perform token transfer from msg.sender to _to.
    /// @param _token The ERC20 token.
    /// @param _to The receiver of the tokens.
    /// @param _share The amount in shares to add.
    /// False if tokens from msg.sender in `spellVault` should be transferred.
    function _addTokens(
        IERC20Upgradeable _token,
        address _to,
        uint256 _share
    ) internal {
        clerk.transfer(_token, msg.sender, address(_to), _share);
    }

    /// @notice Perform the actual borrow.
    /// @dev msg.sender borrow "_amount" of SPELL and transfer to "_to"
    /// @param _to The address to received borrowed SPELL
    /// @param _amount The amount of SPELL to be borrowed
    function _borrow(address _to, uint256 _amount)
        internal
        checkDebtSize
        returns (uint256 _debtShare, uint256 _share)
    {
        // 1. Find out debtShare from the give "_value" that msg.sender wish to borrow
        _debtShare = debtValueToShare(_amount);

        // 2. Update user's debtShare
        userDebtShare[msg.sender] = userDebtShare[msg.sender] + _debtShare;

        // 3. Book totalDebtShare and totalDebtValue
        totalDebtShare = totalDebtShare + _debtShare;
        totalDebtValue = totalDebtValue + _amount;

        // 4. Transfer borrowed SPELL to "_to"
        _share = clerk.toShare(spell, _amount, false);
        clerk.transfer(spell, address(this), _to, _share);

        emit LogBorrow(msg.sender, _to, _amount, _debtShare);
    }

    /// @notice Sender borrows `_amount` and transfers it to `to`.
    /// @dev "checkSafe" modifier prevents msg.sender from borrow > collateralFactor
    /// @param _to The address to received borrowed SPELL
    /// @param _borrowAmount The amount of SPELL to be borrowed
    function borrow(
        address _to,
        uint256 _borrowAmount,
        uint256 _minPrice,
        uint256 _maxPrice
    )
        external
        nonReentrant
        accrue
        updateCollateralPriceWithSlippageCheck(_minPrice, _maxPrice)
        checkSafe
        returns (uint256 _debtShare, uint256 _share)
    {
        // Perform actual borrow
        (_debtShare, _share) = _borrow(_to, _borrowAmount);
    }

    /// @notice Return the debt value of the given debt share.
    /// @param _debtShare The debt share to be convered.
    function debtShareToValue(uint256 _debtShare)
        public
        view
        returns (uint256)
    {
        if (totalDebtShare == 0) return _debtShare;
        uint256 _debtValue = (_debtShare * totalDebtValue) / totalDebtShare;
        return _debtValue;
    }

    /// @notice Return the debt share for the given debt value.
    /// @dev debt share will always be rounded up to prevent tiny share.
    /// @param _debtValue The debt value to be converted.
    function debtValueToShare(uint256 _debtValue)
        public
        view
        returns (uint256)
    {
        if (totalDebtShare == 0) return _debtValue;
        uint256 _debtShare = (_debtValue * totalDebtShare) / totalDebtValue;
        if ((_debtShare * totalDebtValue) / totalDebtShare < _debtValue) {
            return _debtShare + 1;
        }
        return _debtShare;
    }

    /// @notice Deposit collateral to Clerk.
    /// @dev msg.sender deposits `_amount` of `_token` to Clerk. "_to" will be credited with `_amount` of `_token`.
    /// @param _token The address of the token to be deposited.
    /// @param _to The address to be credited with `_amount` of `_token`.
    /// @param _collateralAmount The amount of `_token` to be deposited.
    function deposit(
        IERC20Upgradeable _token,
        address _to,
        uint256 _collateralAmount
    ) external nonReentrant accrue {
        _vaultDeposit(_token, _to, _collateralAmount, 0);
    }

    /// @notice Deposit collateral to Clerk and borrow SPELL
    /// @param _to The address to received borrowed SPELL
    /// @param _collateralAmount The amount of collateral to be deposited
    /// @param _borrowAmount The amount of SPELL to be borrowed
    /// @param _minPrice The minimum price of SPELL to be borrowed to prevent slippage
    /// @param _maxPrice The maximum price of SPELL to be borrowed to prevent slippage
    function depositAndBorrow(
        address _to,
        uint256 _collateralAmount,
        uint256 _borrowAmount,
        uint256 _minPrice,
        uint256 _maxPrice
    )
        external
        nonReentrant
        accrue
        updateCollateralPriceWithSlippageCheck(_minPrice, _maxPrice)
        checkSafe
    {
        // 1. Deposit collateral to the Vault
        (, uint256 _shareOut) = _vaultDeposit(
            collateral,
            msg.sender,
            _collateralAmount,
            0
        );

        // 2. Add collateral
        _addCollateral(msg.sender, _shareOut);

        // 3. Borrow SPELL
        _borrow(msg.sender, _borrowAmount);

        // 4. Withdraw SPELL from Vault to "_to"
        _vaultWithdraw(spell, _to, _borrowAmount, 0);
    }

    /// @notice Update collateral price from Oracle.
    function updateCollateralPrice()
        public
        returns (bool _updated, uint256 _price)
    {
        (_updated, _price) = oracle.get(oracleData);

        if (_updated) {
            collateralPrice = _price;
            emit LogUpdateCollateralPrice(_price);
        } else {
            // Return the old rate if fetching wasn't successful
            _price = collateralPrice;
        }
    }

    /// @notice Perform deposit token from msg.sender and credit token's balance to "_to"
    /// @param _token The token to deposit.
    /// @param _to The address to credit the deposited token's balance to.
    /// @param _amount The amount of tokens to deposit.
    /// @param _share The amount to deposit in share units.
    function _vaultDeposit(
        IERC20Upgradeable _token,
        address _to,
        uint256 _amount,
        uint256 _share
    ) internal returns (uint256, uint256) {
        return
            clerk.deposit(
                _token,
                msg.sender,
                _to,
                uint256(_amount),
                uint256(_share)
            );
    }

    /// @notice Perform debit token's balance from msg.sender and transfer token to "_to"
    /// @param _token The token to withdraw.
    /// @param _to The address of the receiver.
    /// @param _amount The amount to withdraw.
    /// @param _share The amount to withdraw in share.
    function _vaultWithdraw(
        IERC20Upgradeable _token,
        address _to,
        uint256 _amount,
        uint256 _share
    ) internal returns (uint256, uint256) {
        uint256 share_ = _amount > 0
            ? clerk.toShare(_token, _amount, true)
            : _share;
        require(
            _token == collateral || _token == spell,
            "invalid token to be withdrawn"
        );
        if (_token == collateral) {
            require(
                clerk.balanceOf(_token, msg.sender) - share_ >=
                    userCollateralShare[msg.sender],
                "please exclude the collateral"
            );
        }

        return clerk.withdraw(_token, msg.sender, _to, _amount, _share);
    }

    /// @notice Return the current debt of the "_user"
    /// @param _user The address to get the current debt
    function getUserDebtValue(address _user) external view returns (uint256) {
        uint256 _userDebtShare = userDebtShare[_user];
        return debtShareToValue(_userDebtShare);
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
pragma solidity 0.8.9;

interface IOracle {
    function get(bytes calldata data)
        external
        view
        returns (bool _success, uint256 _rate);

    function symbol(bytes calldata data) external view returns (string memory);

    function name(bytes calldata data) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IVaultConfig {
    function collateralFactor(address _vault, address _user)
        external
        view
        returns (uint256);

    function interestPerSecond(address _vault) external view returns (uint256);

    function minDebtSize(address _vault) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "../libraries/MyConversion.sol";

/// @title Clerk contract interface for managing the fund, as well as yield farming
interface IClerk {
    event LogDeposit(
        IERC20Upgradeable indexed token,
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 share
    );
    event LogWithdraw(
        IERC20Upgradeable indexed token,
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 share
    );
    event LogTransfer(
        IERC20Upgradeable indexed token,
        address indexed from,
        address indexed to,
        uint256 share
    );

    event LogWhiteListMarket(address indexed market, bool approved);
    event LogTokenToMarkets(
        address indexed market,
        address indexed token,
        bool approved
    );

    function balanceOf(IERC20Upgradeable, address)
        external
        view
        returns (uint256);

    function deposit(
        IERC20Upgradeable token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256 amountOut, uint256 shareOut);

    function toAmount(
        IERC20Upgradeable token,
        uint256 share,
        bool roundUp
    ) external view returns (uint256 amount);

    function toShare(
        IERC20Upgradeable token,
        uint256 amount,
        bool roundUp
    ) external view returns (uint256 share);

    function totals(IERC20Upgradeable)
        external
        view
        returns (Conversion memory _totals);

    function transfer(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 share
    ) external;

    function whitelistMarket(address market, bool approved) external;

    function whitelistedMarkets(address) external view returns (bool);

    function withdraw(
        IERC20Upgradeable token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256 amountOut, uint256 shareOut);
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

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
        return !AddressUpgradeable.isContract(address(this));
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";

struct Conversion {
    uint128 amount;
    uint128 share;
}

/// @notice A Conversion library for converting amount to share and vice versa
library MyConversion {
    using SafeCast for uint256;

    /// @notice Calculates the share value in relationship to `amount` and `total`.
    function toShare(
        Conversion memory total,
        uint256 amount,
        bool roundUp
    ) internal pure returns (uint256 share) {
        if (total.amount == 0) {
            share = amount;
        } else {
            share = (amount * (total.share)) / total.amount;
            if (roundUp && (share * (total.amount)) / total.share < amount) {
                share = share + 1;
            }
        }
    }

    /// @notice Calculates the amount value in relationship to `share` and `total`.
    function toAmount(
        Conversion memory total,
        uint256 share,
        bool roundUp
    ) internal pure returns (uint256 amount) {
        if (total.share == 0) {
            amount = share;
        } else {
            amount = (share * (total.amount)) / total.share;
            if (roundUp && (amount * (total.share)) / total.amount < share) {
                amount = amount + 1;
            }
        }
    }

    /// @notice Add `amount` to `total` and doubles `total.share`.
    /// @return (Conversion) The new total.
    /// @return share in relationship to `amount`.
    function add(
        Conversion memory total,
        uint256 amount,
        bool roundUp
    ) internal pure returns (Conversion memory, uint256 share) {
        share = toShare(total, amount, roundUp);
        total.amount = total.amount + amount.toUint128();
        total.share = total.share + share.toUint128();
        return (total, share);
    }

    /// @notice Sub `share` from `total` and update `total.amount`.
    /// @return (Conversion) The new total.
    /// @return amount in relationship to `share`.
    function sub(
        Conversion memory total,
        uint256 share,
        bool roundUp
    ) internal pure returns (Conversion memory, uint256 amount) {
        amount = toAmount(total, share, roundUp);
        total.amount = total.amount - amount.toUint128();
        total.share = total.share - share.toUint128();
        return (total, amount);
    }

    /// @notice Add `amount` and `share` to `total`.
    function add(
        Conversion memory total,
        uint256 amount,
        uint256 share
    ) internal pure returns (Conversion memory) {
        total.amount = total.amount + amount.toUint128();
        total.share = total.share + share.toUint128();
        return total;
    }

    /// @notice Subtract `amount` and `share` to `total`.
    function sub(
        Conversion memory total,
        uint256 amount,
        uint256 share
    ) internal pure returns (Conversion memory) {
        total.amount = total.amount - amount.toUint128();
        total.share = total.share - share.toUint128();
        return total;
    }

    /// @notice Add `amount` to `total` and update storage.
    /// @return newAmount Returns updated `amount`.
    function addAmount(Conversion storage total, uint256 amount)
        internal
        returns (uint256 newAmount)
    {
        newAmount = total.amount = total.amount + amount.toUint128();
    }

    /// @notice Subtract `amount` from `total` and update storage.
    /// @return newAmount Returns updated `amount`.
    function subAmount(Conversion storage total, uint256 amount)
        internal
        returns (uint256 newAmount)
    {
        newAmount = total.amount = total.amount - amount.toUint128();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}