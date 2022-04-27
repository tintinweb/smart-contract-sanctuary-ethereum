// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

/**
 * @dev {IERC11554k} interface:
 */
interface IERC11554k {
    function originatorOf(uint256 id) external returns (address);
}

/**
 * @dev {FeesManager} contract
 *
 * The account that deploys the contract will be an owner of the contract,
 * which can be later transferred to a different account.
 */
contract FeesManagerV2 is Initializable, OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    uint256 private constant _percentageFactor = 100;
    uint256 private constant _feesFactor = 10000;
    // Storage fees default debt seizure thresholds.
    uint256 public defaultSeizureThreshold = 1e12;
    // Fees splitting addresses.
    address[] public splitters;
    // Fees splitting percentages.
    uint256[] public percentages;
    // ERC11554k contract address.
    IERC11554k public erc11554k;
    // Exchange contract.
    address public exchange;
    // Allowed storage fees payment tokens;
    mapping(address => bool) public paymentTokens;
    // Storage fees paid to 4K.
    mapping(address => uint256) public paidStorageFees;
    // Accumulated fees.
    mapping(address => mapping(address => uint256)) public fees;
    // Storage fees debt seizure thresholds.
    mapping(uint256 => uint256) public seizureThresholds;
    // Last storage fee set timestamp.
    mapping(uint256 => uint256) public lastFeeSetTime;
    // Trading fees tiers.
    mapping(uint256 => uint256) public tradingFees;
    // Storage fees tiers.
    mapping(uint256 => uint256) public storageFees;
    // Storage fees paid for an item accumulated.
    mapping(uint256 => uint256) public storagePaid;
    // Storage fees to pay for an item accumulated.
    mapping(uint256 => uint256) public storageToPay;

    event ReceivedFees(uint256 id, address owner, address asset, uint256 fee);
    event PaidStorage(uint256 id, address owner, uint256 amount);
    event ClaimFees(address claimer, uint256 fees);
    event ClaimStorageFees(address claimer, uint256 fees);

    constructor() initializer {
        __Ownable_init();
    }

    /**
     * @dev Sets `erc11554k` to `newERC11554k`.
     *
     * Requirements:
     *
     * - the caller must be the `owner`.
     */
    function setERC11554k(IERC11554k newERC11554k) external onlyOwner {
        erc11554k = newERC11554k;
    }

    /**
     * @dev Sets `seizureThreshold` for an item with `id` to `newSeizureThreshold`.
     *
     * Requirements:
     *
     * - the caller must be the `owner`.
     */
    function setSeizureThreshold(uint256 id, uint256 newSeizureThreshold) external onlyOwner {
        seizureThresholds[id] = newSeizureThreshold;
    }

    /**
     * @dev Sets `seizureThresholds` to `newSeizureThresholds`.
     *
     * Requirements:
     *
     * - the caller must be the `owner`.
     */
    function setSeizureThresholds(uint256[] calldata ids, uint256[] calldata newSeizureThresholds)
        external
        onlyOwner
    {
        require(ids.length == newSeizureThresholds.length, "FeesManager: must have equal lengths");
        for (uint256 i = 0; i < ids.length; ++i) {
            seizureThresholds[ids[i]] = newSeizureThresholds[i];
        }
    }

    /**
     * @dev Sets `defaultSeizureThreshold` to `newSeizureThreshold`.
     *
     * Requirements:
     *
     * - the caller must be the `owner`.
     */
    function setDefaultSeizureThreshold(uint256 newSeizureThreshold) external onlyOwner {
        defaultSeizureThreshold = newSeizureThreshold;
    }

    /**
     * @dev Sets trading fee for an item with `id`.
     *
     * Requirements:
     *
     * - the caller must be the `owner`.
     */
    function setTradingFee(uint256 id, uint256 fee) external onlyOwner {
        tradingFees[id] = fee;
    }

    /**
     * @dev Sets trading fees for a list of items.
     *
     * Requirements:
     *
     * - the caller must be the `owner`.
     */
    function setTradingFees(uint256[] calldata ids, uint256[] calldata itemFees)
        external
        onlyOwner
    {
        require(ids.length == itemFees.length, "FeesManager: must have equal lengths");
        for (uint256 i = 0; i < ids.length; ++i) {
            tradingFees[ids[i]] = itemFees[i];
        }
    }

    /**
     * @dev Adds paymentToken to pay fees with.
     *
     * Requirements:
     *
     * - the caller must be the `owner`.
     */
    function addPaymentToken(address paymentToken) external onlyOwner {
        paymentTokens[paymentToken] = true;
    }

    /**
     * @dev Removes paymentToken to pay fees with.
     *
     * Requirements:
     *
     * - the caller must be the `owner`.
     */
    function removePaymentToken(address paymentToken) external onlyOwner {
        paymentTokens[paymentToken] = false;
    }

    /**
     * @dev Sets storage fee for an item with `id`.
     *
     * Requirements:
     *
     * - the caller must be the `owner`.
     */
    function setStorageFee(uint256 id, uint256 fee) external onlyOwner {
        if (lastFeeSetTime[id] > 0) {
            storageToPay[id] += (block.timestamp - lastFeeSetTime[id]) * storageFees[id];
        }
        storageFees[id] = fee;
        lastFeeSetTime[id] = block.timestamp;
    }

    /**
     * @dev Sets storage fees for a list of items.
     *
     * Requirements:
     *
     * - the caller must be the `owner`.
     */
    function setStorageFees(uint256[] calldata ids, uint256[] calldata itemFees)
        external
        onlyOwner
    {
        require(ids.length == itemFees.length, "FeesManager: must have equal lengths");
        for (uint256 i = 0; i < ids.length; ++i) {
            if (lastFeeSetTime[ids[i]] > 0) {
                storageToPay[ids[i]] +=
                    (block.timestamp - lastFeeSetTime[ids[i]]) *
                    storageFees[ids[i]];
            }
            storageFees[ids[i]] = itemFees[i];
            lastFeeSetTime[ids[i]] = block.timestamp;
        }
    }

    /**
     * @dev Sets `exchange` to `newExchange`.
     *
     * Requirements:
     *
     * - the caller must be the `owner`.
     */
    function setExchange(address newExchange) external onlyOwner {
        exchange = newExchange;
    }

    /**
     * @dev Sets `percentages` and `splitters` to `newSplitters` and `newPercentages`.
     *
     * Requirements:
     *
     * - the caller must be the `owner`.
     */
    function setSplitting(address[] calldata newSplitters, uint256[] calldata newPercentages)
        external
        virtual
        onlyOwner
    {
        require(
            newSplitters.length >= 2 && newSplitters.length == newPercentages.length,
            "FeesManager: arguments satisfy splitting condition"
        );
        require(
            newSplitters[0] == address(0),
            "FeesManager: must be 0 address, this field for current item owner"
        );
        require(
            newSplitters[1] == address(0),
            "FeesManager: must be 0 address, this field for current item original owner"
        );
        uint256 sum = 0;
        for (uint256 i = splitters.length; i > 0; --i) {
            splitters.pop();
            percentages.pop();
        }
        for (uint256 i = 0; i < newPercentages.length; ++i) {
            sum += newPercentages[i];
            splitters.push(newSplitters[i]);
            percentages.push(newPercentages[i]);
        }
        require(sum == _percentageFactor, "FeesManager: percentages sum must be 100");
    }

    /**
     * @dev Receive fees `fee` from exchange for item with `id`.
     */
    function calculateFee(uint256 id, uint256 amount) public view virtual returns (uint256) {
        return (tradingFees[id] * amount) / _feesFactor;
    }

    /**
     * @dev Check if seizure by admin is allowed for an item with `id` from `owner`.
     */
    function isSeizureAllowed(uint256 id) public view virtual returns (bool) {
        if (seizureThresholds[id] == 0) {
            return debt(id) >= defaultSeizureThreshold;
        }
        return debt(id) >= seizureThresholds[id];
    }

    /**
     * @dev Pays full debt for storage of item with `id` with `asset`.
     */
    function payStorage(
        uint256 id,
        address owner,
        address token
    ) external virtual {
        require(paymentTokens[token], "FeesManager: token is not allowed for payment");
        uint256 toPay = debt(id);
        if (toPay > 0) {
            paidStorageFees[token] += toPay;
            storagePaid[id] += toPay;
            IERC20Upgradeable(token).safeTransferFrom(owner, address(this), toPay);
        }
        emit PaidStorage(id, _msgSender(), toPay);
    }

    /**
     * @dev Pays amount for storage of item with `id`.
     */
    function payStorageFixed(
        uint256 id,
        address token,
        uint256 amount
    ) external virtual {
        require(paymentTokens[token], "FeesManager: token is not allowed for payment");
        paidStorageFees[token] += amount;
        storagePaid[id] += amount;
        IERC20Upgradeable(token).safeTransferFrom(_msgSender(), address(this), amount);
        emit PaidStorage(id, _msgSender(), amount);
    }

    /**
     * @dev Debt for storage of item with `id`.
     */
    function debt(uint256 id) public view virtual returns (uint256) {
        if (
            storagePaid[id] >=
            storageToPay[id] + (block.timestamp - lastFeeSetTime[id]) * storageFees[id]
        ) {
            return 0;
        }
        return
            storageToPay[id] +
            (block.timestamp - lastFeeSetTime[id]) *
            storageFees[id] -
            storagePaid[id];
    }

    /**
     * @dev Receive fees `fee` from exchange for item with `id`.
     * Requirements:
     *
     * - the caller must be the Exchange contract.
     */
    function receiveFees(
        uint256 id,
        address owner,
        address asset,
        uint256 fee
    ) external virtual {
        require(_msgSender() == exchange, "FeesManager: must receive fees from exchange contract");
        address originator = erc11554k.originatorOf(id);
        fees[asset][owner] += (fee * percentages[0]) / _percentageFactor;
        fees[asset][originator] += (fee * percentages[1]) / _percentageFactor;
        for (uint256 i = 2; i < splitters.length; ++i) {
            fees[asset][splitters[i]] += (fee * percentages[i]) / _percentageFactor;
        }
        emit ReceivedFees(id, owner, asset, fee);
    }

    /**
     * @dev Claim `asset` fees from fees manager.
     */
    function claimFees(address asset) external returns (uint256 claimed) {
        address claimer = _msgSender();
        claimed = fees[asset][claimer];
        fees[asset][claimer] = 0;
        if (claimed > 0) {
            IERC20Upgradeable(asset).safeTransfer(claimer, claimed);
        }
        emit ClaimFees(claimer, claimed);
    }

    /**
     * @dev Claim storage fees by contract owner.
     */
    function claimStorageFees(address token) external onlyOwner returns (uint256 claimed) {
        claimed = paidStorageFees[token];
        paidStorageFees[token] = 0;
        IERC20Upgradeable(token).safeTransfer(_msgSender(), claimed);
        emit ClaimStorageFees(_msgSender(), claimed);
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