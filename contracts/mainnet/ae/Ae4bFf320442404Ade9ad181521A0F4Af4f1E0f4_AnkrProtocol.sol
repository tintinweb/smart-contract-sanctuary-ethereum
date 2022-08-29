// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

interface IAnkrProtocol {

    // tier lifecycle events
    event TierLevelCreated(uint8 level);
    event TierLevelChanged(uint8 level);
    event TierLevelRemoved(uint8 level);

    // jwt token issue
    event TierAssigned(address indexed sender, uint256 amount, uint8 tier, uint256 roles, uint64 expires, bytes32 publicKey);

    // balance management
    event FundsLocked(address indexed sender, uint256 amount);
    event FundsUnlocked(address indexed sender, uint256 amount);
    event FeeCharged(address indexed sender, uint256 fee);

    function deposit(uint256 amount, uint64 timeout, bytes32 publicKey) external;

    function withdraw(uint256 amount) external;
}

interface IRequestFormat {

    function requestWithdrawal(address sender, uint256 amount) external;
}

interface ITransportLayer {

    event ProviderRequest(
        bytes32 id,
        address sender,
        uint256 fee,
        address callback,
        bytes data,
        uint64 expires
    );

    function handleChargeFee(address[] calldata users, uint256[] calldata fees) external;

    function handleWithdraw(address[] calldata users, uint256[] calldata amounts, uint256[] calldata fees) external;
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IERC20Mintable {

    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;
}

interface IERC20Extra {

    function name() external returns (string memory);

    function decimals() external returns (uint8);

    function symbol() external returns (string memory);
}

interface IERC20Pegged {

    function getOrigin() external view returns (uint256, address);
}

interface IERC20InternetBond {

    function ratio() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/utils/Create2Upgradeable.sol";

library AddressGenerator {

    bytes32 public constant DEPLOYMENT_SALT = keccak256("AnkrProtocol");

    function makeSureProtocolAddressDeterministic(address that, address sender) internal pure {
        address shouldBe = Create2Upgradeable.computeAddress(
            DEPLOYMENT_SALT,
            computeBytecodeHashEmptyConstructor(),
            sender
        );
        require(that == shouldBe, "AnkrProtocol: non-deterministic address");
    }

    function computeBytecodeHashEmptyConstructor() internal pure returns (bytes32 hash) {
        assembly {
            let length := codesize()
            let bytecode := mload(0x40)
            mstore(0x40, add(bytecode, and(add(add(length, 0x20), 0x1f), not(0x1f))))
            mstore(bytecode, length)
            codecopy(add(bytecode, 0x20), 0, length)
            hash := keccak256(bytecode, add(bytecode, length))
        }
    }

    function computeBytecodeHashWithConstructor() internal pure returns (bytes32 hash) {
        bytes memory bytecode;
        assembly {
            let length := codesize()
            bytecode := mload(0x40)
            mstore(0x40, add(bytecode, and(add(add(length, 0x20), 0x1f), not(0x1f))))
            mstore(bytecode, length)
            codecopy(add(bytecode, 0x20), 0, length)
        }
        uint256 ctor = 2;
        while (ctor < bytecode.length - 1 || bytecode[ctor + 0] != 0x60 || bytecode[ctor + 1] != 0x80) {
            ctor++;
        }
        require(ctor < bytecode.length - 1, "AnkrProtocol: ctor not found");
        assembly {
            let length := mload(bytecode)
            hash := keccak256(add(bytecode, ctor), add(bytecode, sub(length, ctor)))
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.7;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

import "../interfaces/IAnkrProtocol.sol";
import "../interfaces/IERC20.sol";

import "../libs/AddressGenerator.sol";

interface IManuallyFeedCollectedFee {

    function manuallyFeedCollectedFee(uint256 amount) external;
}

contract AnkrProtocol is ReentrancyGuardUpgradeable {

    event TierLevelCreated(uint8 level);
    event TierLevelChanged(uint8 level);
    event TierLevelRemoved(uint8 level);

    event TierAssigned(address indexed sender, uint256 amount, uint8 tier, uint256 roles, uint64 expires, bytes32 publicKey);
    event FundsLocked(address indexed sender, uint256 amount, uint256 fee);
    event FundsUnlocked(address indexed sender, uint256 amount, uint8 tier);
    event FeeCharged(address indexed sender, uint256 fee);
    event FeeWithdrawn(address recipient, uint256 amount);

    struct TierLevel {
        uint256 threshold;
        uint256 fee;
        uint256 roles;
        uint8 tier;
    }

    struct UserDeposit {
        // available (how much user can spend), total (available+charged), pending (pending unlock)
        uint256 available;
        uint256 total;
        uint256 pending;
        // level based on deposited amount
        uint8 tier;
        uint64 expires;
    }

    struct RequestPayload {
        address sender;
        uint256 fee;
        address callback;
        bytes4 sig;
        uint64 lifetime;
        bytes data;
    }

    IERC20Upgradeable private _ankrToken;
    TierLevel[] private _tierLevels;
    mapping(address => UserDeposit) private _userDeposits;
    address private _governance;
    address private _consensus;
    mapping(address => uint256) private _requestNonce;
    uint256 private _collectedFee;
    address private _enterpriseAdmin;

    function initialize(IERC20Upgradeable ankrToken, address governance, address consensus) external initializer {
        __ReentrancyGuard_init();
        __AnkrProtocol_init(ankrToken, governance, consensus);
    }

    function __AnkrProtocol_init(IERC20Upgradeable ankrToken, address governance, address consensus) internal {
        // init fields
        _ankrToken = ankrToken;
        _governance = governance;
        _consensus = consensus;
        // create zero vip level
        _tierLevels.push(TierLevel({
        threshold : 0,
        tier : 0,
        roles : 0,
        fee : 0
        }));
    }

    modifier onlyFromGovernance() virtual {
        require(msg.sender == address(_governance), "AnkrProtocol: not governance");
        _;
    }

    modifier onlyFromConsensus() virtual {
        require(msg.sender == address(_consensus), "AnkrProtocol: not consensus");
        _;
    }

    modifier onlyFromEnterpriseAdmin() virtual {
        require(msg.sender == address(_enterpriseAdmin), "AnkrProtocol: not enterprise admin");
        _;
    }

    function createTierLevel(uint8 tier, uint256 threshold, uint256 roles, uint256 fee) external onlyFromGovernance {
        require(tier == _tierLevels.length, "AnkrProtocol: out of order");
        // if its not first level then make sure its not lower than previous (lets allow to set equal amount)
        uint256 prevThreshold = _tierLevels[tier - 1].threshold;
        require(prevThreshold >= 0 && threshold >= prevThreshold, "AnkrProtocol: threshold too low");
        // add new vip level
        _tierLevels.push(TierLevel({
        threshold : threshold,
        tier : tier,
        roles : roles,
        fee : fee
        }));
        emit TierLevelCreated(tier);
    }

    function changeTierLevel(uint8 level, uint256 threshold, uint256 fee) external onlyFromGovernance {
        require(_tierLevels[level].tier > 0, "AnkrProtocol: level doesn't exist");
        _tierLevels[level].threshold = threshold;
        _tierLevels[level].fee = fee;
        emit TierLevelChanged(level);
    }

    function calcNextTierLevel(address user, uint256 amount) external view returns (TierLevel memory) {
        UserDeposit memory userDeposit = _userDeposits[user];
        return _matchTierLevelOf(userDeposit.total + amount);
    }

    function _matchTierLevelOf(uint256 balance) internal view returns (TierLevel memory) {
        if (_tierLevels.length == 1) {
            return _tierLevels[0];
        }
        for (uint256 i = _tierLevels.length - 1; i >= 0; i--) {
            TierLevel memory level = _tierLevels[i];
            if (balance >= level.threshold) {
                return level;
            }
        }
        revert("AnkrProtocol: can't match level");
    }

    function getDepositLevel(uint8 level) external view returns (TierLevel memory) {
        return _tierLevels[level];
    }

    function currentLevel(address user) external view returns (uint8 tier, uint64 expires, uint256 roles) {
        UserDeposit memory userDeposit = _userDeposits[user];
        TierLevel memory depositLevel = _tierLevels[userDeposit.tier];
        return (userDeposit.tier, userDeposit.expires, depositLevel.roles);
    }

    function deposit(uint256 amount, uint64 timeout, bytes32 publicKey) external nonReentrant {
        require(timeout <= 31536000, "timeout can't be greater than 1 year");
        _lockDeposit(msg.sender, amount, timeout, publicKey);
    }

    function assignTier(uint64 timeout, uint8 tier, address user, bytes32 publicKey) external onlyFromEnterpriseAdmin {
        require(tier < _tierLevels.length, "AnkrProtocol: wrong tier level");
        require(timeout <= 3153600000, "timeout can't be greater than 100 year");
        TierLevel memory level = _tierLevels[tier];
        UserDeposit memory userDeposit = _userDeposits[user];
        userDeposit.tier = level.tier;
        _userDeposits[user] = userDeposit;
        // emit event
        emit TierAssigned(user, 0, level.tier, level.roles, uint64(block.timestamp) + timeout, publicKey);
    }

    function _lockDeposit(address user, uint256 amount, uint64 timeout, bytes32 publicKey) internal {
        // transfer ERC20 tokens when its required
        if (amount > 0) {
            require(_ankrToken.transferFrom(user, address(this), amount), "Ankr Protocol: can't transfer");
        }
        // obtain user's lock and match next tier level
        UserDeposit memory userDeposit = _userDeposits[user];
        TierLevel memory newLevel = _matchTierLevelOf(userDeposit.total + amount);
        // check do we need to charge for level increase
        if (newLevel.fee > 0 && (newLevel.tier > userDeposit.tier || userDeposit.expires > block.timestamp)) {
            amount -= newLevel.fee;
            _collectedFee += newLevel.fee;
        }
        // increase locked amount
        userDeposit.total += amount;
        userDeposit.available += amount;
        // if we have no expires set then increase it
        if (userDeposit.expires == 0) {
            userDeposit.expires = uint64(block.timestamp) + timeout;
        }
        // save new tier
        userDeposit.tier = newLevel.tier;
        _userDeposits[user] = userDeposit;
        // emit event
        emit TierAssigned(user, amount, userDeposit.tier, newLevel.roles, userDeposit.expires, publicKey);
        emit FundsLocked(user, amount, newLevel.fee);
    }

    function withdraw(uint256 /*amount*/, uint256 /*fee*/) external nonReentrant {
        revert("not supported yet");
    }

    function _validateWithdrawal(UserDeposit memory lock, uint256 amount) internal view {
        require(lock.expires <= block.timestamp, "AnkrProtocol: too early to withdraw");
        require(lock.available >= amount, "AnkrProtocol: insufficient balance");
    }

    function getCollectedFee() external view returns (uint256) {
        return _collectedFee;
    }

    function transferCollectedFee(IManuallyFeedCollectedFee recipient, uint256 amount) external onlyFromGovernance {
        require(amount <= _collectedFee, "AnkrProtocol: insufficient fee");
        _collectedFee -= amount;
        _ankrToken.approve(address(recipient), amount);
        recipient.manuallyFeedCollectedFee(amount);
        emit FeeWithdrawn(address(recipient), amount);
    }

    function changeConsensus(address newConsensus) external onlyFromGovernance {
        _consensus = newConsensus;
    }

    function changeGovernance(address newGovernance) external onlyFromGovernance {
        _governance = newGovernance;
    }

    function changeEnterpriseAdmin(address newEnterpriseAdmin) external onlyFromGovernance {
        _enterpriseAdmin = newEnterpriseAdmin;
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
// OpenZeppelin Contracts v4.4.1 (utils/Create2.sol)

pragma solidity ^0.8.0;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2Upgradeable {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(
        uint256 amount,
        bytes32 salt,
        bytes memory bytecode
    ) internal returns (address) {
        address addr;
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
        return addr;
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(
        bytes32 salt,
        bytes32 bytecodeHash,
        address deployer
    ) internal pure returns (address) {
        bytes32 _data = keccak256(abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash));
        return address(uint160(uint256(_data)));
    }
}