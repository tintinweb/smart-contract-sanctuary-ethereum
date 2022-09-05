//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../AssetPool.sol";

contract MockAssetPool is AssetPool {
    uint internal month;

    function MONTH_TIME() public view override returns (uint) {
        return month == 0 ? 5 minutes : month;
    }

    function initialize(Pool memory info) external override initializer {
        require(info.minAmount < info.maxAmount, "Min amount have to lower than Max amount");
        poolInfo = info;
        assetManager = IAssetManager(msg.sender);
    }

    function setMonth(uint _month) external {
        month = _month;
    }

    function getFeeInfo() external view returns (Fee memory) {
        return feeInfo;
    }
}

//SPDX-License-Identifier: Unlicense
// solhint-disable not-rely-on-time
// solhint-disable func-name-mixedcase
// solhint-disable avoid-low-level-calls
pragma solidity ^0.8.10;

import "./interfaces/IAssetPool.sol";
import "./interfaces/IAssetManager.sol";
import "./libraries/UtilUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract AssetPool is IAssetPool, Initializable {
    using UtilUpgradeable for address;

    Pool public poolInfo;
    IAssetManager public assetManager;

    mapping(address => uint) internal shares;
    uint public sharesTotal;

    mapping(address => uint) internal sharesPhase;
    uint internal shareCurrentPhase;

    Fee internal feeInfo;

    uint public constant PRECISION_DECIMALS = 1e4;

    event Deposit(address user, address token, uint amount);
    event Withdraw(address user, address token, uint amount);
    event FeeSent(address token, uint amount);
    event Invest(Action[] actions);

    // Psudo constant - for override value
    function MONTH_TIME() public view virtual returns (uint) {
        return 30 days;
    }

    function initialize(Pool memory info) external virtual initializer {
        require(info.minAmount < info.maxAmount, "Min amount higher or equal Max");
        poolInfo = info;
        assetManager = IAssetManager(msg.sender);
    }

    modifier onlyManager() {
        require(msg.sender == poolInfo.manager, "Not manager");
        _;
    }

    function deposit(address token, uint amount) public payable {
        Pool memory info = poolInfo;
        address user = msg.sender == address(assetManager) ? info.manager : msg.sender;

        require(assetManager.tokenSupported(token), "Token not supported");
        if (user != info.manager) require(info.isOpen, "Not open");
        require(amount > 0, "Invalid amount");
        token.transferToThis(amount);

        uint liquidityAdded = assetManager.getUsdAmount(token, amount);
        require(liquidityAdded >= info.minAmount, "Deposit below limit");
        (uint liquidity, uint feeTotal) = _getLiquidityAndFee(liquidityAdded);
        (uint shareMinted, bool isPhaseChanged) = _getShareMinted(liquidity, liquidityAdded);

        _updateFee(feeTotal);
        _mintTotalShare(isPhaseChanged, shareMinted);
        _mintShare(user, shareMinted);

        uint liquidityAfterDeposit = liquidity + liquidityAdded;
        uint userLiquidity = (liquidityAfterDeposit * userShare(user)) / sharesTotal;
        require(userLiquidity <= info.maxAmount, "Deposit over limit");

        emit Deposit(user, token, amount);
    }

    function _getShareMinted(uint liquidity, uint liquidityAdded)
        internal
        view
        returns (uint shareMinted, bool isPhaseChanged)
    {
        if (liquidity == 0) {
            shareMinted = liquidityAdded;
            if (sharesTotal > 0) {
                isPhaseChanged = true;
            }
        } else {
            shareMinted = (liquidityAdded * sharesTotal) / liquidity;
        }
    }

    function _mintTotalShare(bool isPhaseChanged, uint shareMinted) internal {
        if (isPhaseChanged) {
            sharesTotal = shareMinted;
            shareCurrentPhase++;
        } else {
            sharesTotal += shareMinted;
        }
    }

    function _mintShare(address user, uint shareMinted) internal {
        if (sharesPhase[user] == shareCurrentPhase) {
            shares[user] += shareMinted;
        } else {
            shares[user] = shareMinted;
            sharesPhase[user] = shareCurrentPhase;
        }
    }

    function withdraw(address token, uint amount) external {
        require(assetManager.tokenSupported(token), "Token not supported");
        require(amount > 0, "Invalid amount");
        address user = msg.sender;
        if (user == poolInfo.manager) {
            require(userShare(user) == sharesTotal, "Others have not withraw");
        }

        uint liquidityRemoved = assetManager.getUsdAmount(token, amount);
        (uint liquidity, uint fee, uint feeTotal) = _getLiquidityAndFee(token);
        uint shareBurnt = _getShareBurnt(liquidity, liquidityRemoved);
        require(amount + fee <= token.getBalance(address(this)), "Have no balance to withdraw");

        _updateFee(feeTotal);
        _burnShare(user, shareBurnt);
        _sendFee(token, fee, feeTotal);

        token.transfer(user, amount);

        emit Withdraw(user, token, amount);
    }

    function _getShareBurnt(uint liquidity, uint liquidityRemoved) internal view returns (uint shareBurnt) {
        if (liquidity > 0) {
            shareBurnt = (sharesTotal * liquidityRemoved) / liquidity;
        }
    }

    function _burnShare(address user, uint shareBurnt) internal {
        require(shareBurnt <= userShare(user), "Withdraw more than share");
        shares[user] -= shareBurnt;
        sharesTotal -= shareBurnt;
    }

    function invest(Action[] calldata actions) external onlyManager {
        (, uint feeTotal) = _getLiquidityAndFee();
        _updateFee(feeTotal);

        for (uint i = 0; i < actions.length; i++) {
            Action memory action = actions[i];
            (bool success, ) = action.to.call{value: action.value}(action.data);
            require(success, "Contract call fail");
        }

        emit Invest(actions);
    }

    function claimFee(address token) external onlyManager {
        require(assetManager.tokenSupported(token), "Token not supported");

        uint balance = token.getBalance(address(this));
        require(balance > 0, "Have no balance to claim");

        (, uint fee, uint feeTotal) = _getLiquidityAndFee(token);
        require(fee > 0, "Have no fee to claim");

        _sendFee(token, fee, feeTotal);
    }

    function _updateFee(uint feeTotal) internal {
        if (feeInfo.pendingAmount != feeTotal) {
            feeInfo.pendingAmount = feeTotal;
        }
        _updateLastMonthTime();
    }

    function _updateLastMonthTime() internal {
        uint lastMonthTime = feeInfo.lastMonthTime;
        if (lastMonthTime == 0) feeInfo.lastMonthTime = uint40(block.timestamp);
        else {
            uint monthSpan = _getMonthSpan(lastMonthTime);
            if (monthSpan > 0) {
                feeInfo.lastMonthTime = uint40(lastMonthTime + monthSpan * MONTH_TIME());
            }
        }
    }

    function _getMonthSpan(uint lastMonthTime) internal view returns (uint) {
        if (lastMonthTime == 0) return 0;
        uint timeSpan = block.timestamp - lastMonthTime;
        return timeSpan / MONTH_TIME();
    }

    function _sendFee(
        address token,
        uint fee,
        uint feeTotal
    ) internal {
        uint feeRemained = feeTotal - assetManager.getUsdAmount(token, fee);
        _updateFee(feeRemained);
        token.transfer(poolInfo.manager, fee);

        emit FeeSent(token, fee);
    }

    function feeAmount(address token) external view returns (uint amount, uint amountTotalUsd) {
        require(assetManager.tokenSupported(token), "Token not supported");
        (, amount, amountTotalUsd) = _getLiquidityAndFee(token);
    }

    function withdrawableAmount(address user, address token)
        external
        view
        returns (uint amount, uint amountTotalUsd)
    {
        require(assetManager.tokenSupported(token), "Token not supported");
        if (sharesTotal > 0) {
            (uint liquidity, uint fee, ) = _getLiquidityAndFee(token);
            amountTotalUsd = (liquidity * userShare(user)) / sharesTotal;
            if (amountTotalUsd > 0) {
                uint balance = token.getBalance(address(this)) - fee;
                amount = assetManager.getAmountFromUsd(token, amountTotalUsd);
                amount = amount > balance ? balance : amount;
            }
        }
    }

    function userShare(address user) public view returns (uint) {
        return _userShare(user, 0);
    }

    function _userShare(address user, uint liquidity) internal view returns (uint share) {
        if (sharesPhase[user] == shareCurrentPhase) {
            return shares[user];
        }
    }

    function setPoolInfo(Pool memory pool) external onlyManager {
        if (pool.manager == address(0)) pool.manager = msg.sender;
        require(pool.maxAmount > pool.minAmount, "Max amount have to > min amount");
        require(pool.manager == msg.sender || userShare(msg.sender) == 0, "Others have not withraw");
        poolInfo = pool;
    }

    // General internal

    function _getLiquidityAndFee() internal view returns (uint liquidity, uint feeTotal) {
        return _getLiquidityAndFee(0);
    }

    function _getLiquidityAndFee(uint liquidityAdded) internal view returns (uint liquidity, uint feeTotal) {
        liquidity = assetManager.getUsdBalance(address(this)) - liquidityAdded;
        feeTotal = _calculateFeeTotal(liquidity);
        liquidity -= feeTotal;
    }

    function _getLiquidityAndFee(address token)
        internal
        view
        returns (
            uint liquidity,
            uint fee,
            uint feeTotal
        )
    {
        return _getLiquidityAndFee(token, 0);
    }

    function _getLiquidityAndFee(address token, uint liquidityAdded)
        internal
        view
        returns (
            uint liquidity,
            uint fee,
            uint feeTotal
        )
    {
        liquidity = assetManager.getUsdBalance(address(this)) - liquidityAdded;
        (fee, feeTotal) = _calculateFees(token, liquidity);
        liquidity -= feeTotal;
    }

    function _calculateFeeTotal(uint liquidity) internal view returns (uint feeTotal) {
        Fee memory info = feeInfo;
        uint monthSpan = _getMonthSpan(info.lastMonthTime);
        uint feeRate = poolInfo.feeMonthlyRate * monthSpan;
        uint updatedFee = (liquidity * feeRate) / PRECISION_DECIMALS;
        feeTotal = info.pendingAmount + updatedFee;
        if (feeTotal > liquidity) feeTotal = liquidity;
    }

    function _calculateFees(address token, uint liquidity) internal view returns (uint fee, uint feeTotal) {
        feeTotal = _calculateFeeTotal(liquidity);
        uint balance = token.getBalance(address(this));
        fee = (balance * feeTotal) / liquidity;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

interface IAssetPool {
    struct Pool {
        address manager;
        bool isOpen;
        uint16 feeMonthlyRate;
        uint minAmount;
        uint maxAmount;
    }

    struct Action {
        address to;
        uint value;
        bytes data;
    }

    struct Fee {
        uint pendingAmount;
        uint40 lastMonthTime;
    }

    function deposit(address token, uint amount) external payable;

    function withdraw(address token, uint amount) external;

    function invest(Action[] calldata actions) external;

    function claimFee(address token) external;

    function setPoolInfo(Pool memory pool) external;

    function poolInfo()
        external
        view
        returns (
            address manager,
            bool isOpen,
            uint16 feeMonthlyRate,
            uint minAmount,
            uint maxAmount
        );

    function userShare(address user) external view returns (uint);

    function sharesTotal() external view returns (uint);

    function withdrawableAmount(address user, address token)
        external
        view
        returns (uint amount, uint amountTotalUsd);

    function feeAmount(address token) external view returns (uint amount, uint amountTotalUsd);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "./IExchange.sol";
import "./IAssetPool.sol";

interface IAssetManager {
    struct CreatePoolConfig {
        address token;
        uint initAmount;
    }

    function createPool(IAssetPool.Pool memory pool, bool isPublic) external payable;

    function setExchange(IExchange _exchange) external;

    function setBeacon(address _beacon) external;

    function setCreatePoolConfig(CreatePoolConfig memory config) external;

    function addTokenSupported(address token) external;

    function removeTokenSupported(address token) external;

    function usd() external view returns (address);

    function exchange() external view returns (IExchange);

    function beacon() external view returns (address);

    function configCreatePool() external view returns (address token, uint initAmount);

    function tokenSupported(address token) external view returns (bool);

    function tokensList() external view returns (address[] memory);

    function getUsdBalance(address account) external view returns (uint);

    function getUsdAmount(address token, uint amount) external view returns (uint);

    function getAmountFromUsd(address token, uint amount) external view returns (uint);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

library UtilUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    function getBalance(address token, address account) internal view returns (uint) {
        if (token == address(0)) {
            return payable(account).balance;
        } else {
            return IERC20Upgradeable(token).balanceOf(account);
        }
    }

    function transfer(
        address token,
        address account,
        uint amount
    ) internal {
        if (token == address(0)) {
            payable(account).transfer(amount);
        } else {
            IERC20Upgradeable(token).safeTransfer(account, amount);
        }
    }

    function transferToThis(address token, uint amount) internal {
        if (token == address(0)) {
            require(msg.value == amount, "Invalid ETH amount");
        } else {
            require(msg.value == 0, "Invalid ETH amount");
            IERC20Upgradeable(token).safeTransferFrom(msg.sender, address(this), amount);
        }
    }

    function transferFrom(
        address token,
        address from,
        address to,
        uint amount
    ) internal {
        IERC20Upgradeable(token).safeTransferFrom(from, to, amount);
    }

    function approve(
        address token,
        address spender,
        uint amount
    ) internal {
        IERC20Upgradeable(token).safeApprove(spender, amount);
    }
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

interface IExchange {
    function getAmountsOut(uint amountIn, address[] calldata path)
        external
        view
        returns (uint[] memory amounts);

    function getAmountsIn(uint amountOut, address[] calldata path)
        external
        view
        returns (uint[] memory amounts);
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