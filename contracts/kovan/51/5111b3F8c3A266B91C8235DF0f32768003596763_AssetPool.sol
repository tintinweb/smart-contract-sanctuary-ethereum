//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interfaces/IAssetPool.sol";
import "./interfaces/IAssetManager.sol";
import "./libraries/Util.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract AssetPool is IAssetPool, Ownable, Initializable {
    Pool public poolInfo;

    mapping(address => uint) internal shares;
    uint public sharesTotal;

    mapping(address => uint) internal sharesPhase;
    uint internal shareCurrentPhase;

    Fee internal feeInfo;

    uint internal constant PRECISION_DECIMALS = 1e4;

    // Psudo constant - for override value
    function MONTH_TIME() internal view virtual returns (uint) {
        return 30 days;
    }

    function initialize(Pool memory info) external initializer {
        require(info.minAmount < info.maxAmount, "Min amount have to lower than Max amount");
        poolInfo = info;
    }

    modifier onlyManager() {
        require(msg.sender == poolInfo.manager, "Not manager");
        _;
    }

    function deposit(address token, uint amount) public payable override {
        Pool memory info = poolInfo;
        require(info.isOpen, "Not open");
        require(assetManager().tokenSupported(token), "Token not supported");
        require(amount > 0, "Invalid amount");

        address user = msg.sender == owner() ? info.manager : msg.sender;
        if (token == address(0)) {
            require(msg.value == amount, "Invalid ETH amount");
        } else {
            IERC20(token).transferFrom(msg.sender, address(this), amount);
        }

        (uint shareMinted, uint feeTotal, bool isPhaseChanged) = _getMintShareAmounts(token, amount);
        _updateFee(feeTotal);
        _mintTotalShare(isPhaseChanged, shareMinted);
        _mintShare(user, shareMinted);
    }

    function _getMintShareAmounts(address token, uint amount)
        internal
        view
        returns (
            uint shareMinted,
            uint feeTotal,
            bool isPhaseChanged
        )
    {
        Pool memory info = poolInfo;
        uint usdDeposited = assetManager().getUsdAmount(token, amount);
        require(usdDeposited >= info.minAmount && usdDeposited <= info.maxAmount, "Deposit not in limit");
        uint liquidity = assetManager().getUsdBalance(address(this)) - usdDeposited;
        liquidity -= feeTotal = _calculateFeeTotal(liquidity);
        if (liquidity == 0) {
            shareMinted = usdDeposited;
            if (sharesTotal > 0) {
                isPhaseChanged = true;
            }
        } else {
            shareMinted = (usdDeposited * sharesTotal) / liquidity;
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

    function withdraw(address token, uint amount) external override {
        require(assetManager().tokenSupported(token), "Token not supported");
        require(amount > 0, "Invalid amount");
        address user = msg.sender;
        if (user == poolInfo.manager) {
            require(userShare(user) == sharesTotal, "Others have not withraw");
        }

        (uint shareBurnt, uint fee, uint feeTotal) = _getBurnShareAmounts(token, amount);
        require(amount <= Util.getBalance(token, address(this)) - fee, "Have no balance to withdraw");
        _updateFee(feeTotal);
        _burnShare(user, shareBurnt);
        _sendFee(token, fee, feeTotal);

        Util.transfer(token, user, amount);
    }

    function _getBurnShareAmounts(address token, uint amount)
        internal
        view
        returns (
            uint shareBurnt,
            uint fee,
            uint feeTotal
        )
    {
        uint usdWithdrawn = assetManager().getUsdAmount(token, amount);
        uint liquidity = assetManager().getUsdBalance(address(this));
        (fee, feeTotal) = _calculateFee(token, liquidity);
        liquidity -= feeTotal;
        if (liquidity > 0) {
            shareBurnt = (sharesTotal * usdWithdrawn) / liquidity;
        }
    }

    function _burnShare(address user, uint shareBurnt) internal {
        require(shareBurnt <= userShare(user), "Withdraw more than share");
        shares[user] -= shareBurnt;
        sharesTotal -= shareBurnt;
    }

    function invest(Action[] calldata actions) external override onlyManager {
        uint liquidity = assetManager().getUsdBalance(address(this));
        uint feeTotal = _calculateFeeTotal(liquidity);
        _updateFee(feeTotal);

        for (uint i = 0; i < actions.length; i++) {
            Action memory action = actions[i];
            (bool success, ) = action.to.call{value: action.value}(action.data);
            require(success, "Contract call fail");
        }
    }

    function claimFee(address token) external override onlyManager {
        require(assetManager().tokenSupported(token), "Token not supported");
        uint balance = Util.getBalance(token, address(this));
        require(balance > 0, "Have no balance to claim");
        uint liquidity = assetManager().getUsdBalance(address(this));
        (uint fee, uint feeTotal) = _calculateFee(token, liquidity);
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

    function _calculateFeeTotal(uint liquidity) internal view returns (uint feeTotal) {
        Fee memory info = feeInfo;
        uint monthSpan = _getMonthSpan(info.lastMonthTime);
        uint feeRate = poolInfo.feeMonthlyRate * monthSpan;
        uint updatedFee = (liquidity * feeRate) / PRECISION_DECIMALS;
        feeTotal = info.pendingAmount + updatedFee;
        if (feeTotal > liquidity) feeTotal = liquidity;
    }

    function _calculateFee(address token, uint liquidity) internal view returns (uint fee, uint feeTotal) {
        feeTotal = _calculateFeeTotal(liquidity);
        uint balance = Util.getBalance(token, address(this));
        fee = (balance * feeTotal) / liquidity;
    }

    function _sendFee(
        address token,
        uint fee,
        uint feeTotal
    ) internal {
        uint feeRemained = feeTotal - assetManager().getUsdAmount(token, fee);
        _updateFee(feeRemained);
        Util.transfer(token, poolInfo.manager, fee);
    }

    function feeAmount(address token) external view returns (uint amount, uint amountTotalUsd) {
        require(assetManager().tokenSupported(token), "Token not supported");
        uint liquidity = assetManager().getUsdBalance(address(this));
        return _calculateFee(token, liquidity);
    }

    function withdrawableAmount(address user, address token)
        external
        view
        returns (uint amount, uint amountTotalUsd)
    {
        require(assetManager().tokenSupported(token), "Token not supported");
        if (sharesTotal > 0) {
            uint liquidity = assetManager().getUsdBalance(address(this));
            (uint fee, uint feeTotal) = _calculateFee(token, liquidity);
            liquidity -= feeTotal;
            amountTotalUsd = (liquidity * userShare(user)) / sharesTotal;
            if (amountTotalUsd > 0) {
                uint balance = Util.getBalance(token, address(this)) - fee;
                amount = assetManager().getAmountFromUsd(token, amountTotalUsd);
                amount = amount > balance ? balance : amount;
            }
        }
    }

    function userShare(address user) public view returns (uint share) {
        if (sharesPhase[user] == shareCurrentPhase) return shares[user];
    }

    function assetManager() internal view returns (IAssetManager) {
        return IAssetManager(owner());
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IAssetPool {
    struct Pool {
        address manager;
        bool isOpen;
        uint minAmount;
        uint maxAmount;
        uint feeMonthlyRate;
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
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IAssetManager {
    struct CreatePoolConfig {
        address token;
        uint minAmount;
    }

    function tokenSupported(address token) external view returns (bool);

    function getUsdBalance(address account) external view returns (uint);

    function getUsdAmount(address token, uint amount) external view returns (uint);

    function getAmountFromUsd(address token, uint amount) external view returns (uint);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library Util {
    function getBalance(address token, address account) internal view returns (uint) {
        if (token == address(0)) {
            return payable(account).balance;
        } else {
            return IERC20(token).balanceOf(account);
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
            IERC20(token).transfer(account, amount);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

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
                version == 1 && !Address.isContract(address(this)),
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