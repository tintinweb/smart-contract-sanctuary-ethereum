// SPDX-License-Identifier: MS-LPL
pragma solidity ^0.8.0;

import "./Locker.sol";
import "./TokensRegister.sol";
import "./ValidatorsRegister.sol";
import "./GatewayStorage.sol";
import "./ITokensRegister.sol";

/// Contract wasn't properly initialized.
/// @param version required storage version.
error NotInitialized(uint8 version);
/// Gateway is not yet activated.
/// @param activeAfter timestamp when gateway will be ready.
error NotActivated(uint64 activeAfter);
/// Not enough signatures where specified.
/// @param minAmount minimal amount of signature to release funds.
error NotEnoughSignatures(uint64 minAmount);
/// Not enough valid signatures where specified.
/// @param validAmount amount of valid signatures.
/// @param minAmount minimal amount of signature to release funds.
error NotEnoughValidSignatures(uint64 validAmount, uint64 minAmount);
/// The validators limit reached.
/// @param maxValidators validators limit.
error TooManuValidators(uint256 maxValidators);
/// The specified token is in use: there is balance on the gateway,
/// or totalSupply is not zero for mintable.
/// @param token token address.
error TokenInUse(address token);

contract Gateway is GatewayStorage, Locker, ValidatorsRegister, TokensRegister {
    event TokenAdd(address indexed token, TokenDef tokenDef);
    event TokenRemove(address indexed token);
    event TokenUpdated(address indexed token, TokenDef tokenDef);

    event ValidatorAdd(address indexed account);
    event ValidatorRemove(address indexed account);

    address constant NATIVE_TOKEN = 0x0000000000000000000000000000000000000000;
    uint256 constant MAX_VALIDATORS = 1000;
    uint8 constant STORAGE_VERSION = 2;

    modifier onlyInitialized() {
        if (_getInitializedVersion() != STORAGE_VERSION) {
            revert NotInitialized(STORAGE_VERSION);
        }
        if (block.timestamp < activateTimestamp()) {
            revert NotActivated(activateTimestamp());
        }
        _;
    }

    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    function lock(IERC20Metadata token, uint256 amount, bytes32 foreignAccount) public onlyInitialized {
        _lock(token, _msgSender(), amount, foreignAccount, feePool);
    }

    function lockEth(bytes32 foreignAccount) public payable onlyInitialized {
        _lockEth(NATIVE_TOKEN, _msgSender(), msg.value, foreignAccount, feePool);
    }

    function getEncoded(address token, uint256 amount, address account, uint64 externalId, uint64 timestamp) public view returns (bytes memory) {
        return abi.encodePacked(token, amount, account, externalId, bytes32(block.chainid), timestamp);
    }

    function getHashed(address token, uint256 amount, address account, uint64 externalId, uint64 timestamp) public view returns (bytes32) {
        return sha256(getEncoded(token, amount, account, externalId, timestamp));
    }

    function verifySignature(address token, uint256 amount, address account, uint64 externalId, uint64 timestamp, Signature calldata signature) public view returns (bool) {
        bytes32 hash = getHashed(token, amount, account, externalId, timestamp);
        address validator = ecrecover(hash, signature.v, signature.r, signature.s);
        return _getValidator(validator) != 0;
    }

    function verifySignatures(address token, uint256 amount, address account, uint64 externalId, uint64 timestamp, Signature[] calldata signatures) public view returns (bool[] memory) {
        bool[] memory result = new bool[](signatures.length);
        bytes32 hash = getHashed(token, amount, account, externalId, timestamp);
        for (uint256 i = 0; i < signatures.length; i ++) {
            address validator = ecrecover(hash, signatures[i].v, signatures[i].r, signatures[i].s);
            result[i] = _getValidator(validator) != 0;
        }
        return result;
    }

    function release(address token, uint256 amount, address account, uint64 externalId, uint64 timestamp, Signature[] calldata signatures) public onlyInitialized {
        uint32 requiredSignatures = getRequiredSignatures();
        if (signatures.length < requiredSignatures) {
            revert NotEnoughSignatures(requiredSignatures);
        }
        bytes memory encoded = abi.encodePacked(token, amount, account, externalId, bytes32(block.chainid), timestamp);
        bytes32 hash = sha256(encoded);
        uint32 counter = 0;
        bool[] memory used = new bool[](_getLastValidatorId() + 1);
        for (uint256 i = 0; i < signatures.length; i ++) {
            address validator = ecrecover(hash, signatures[i].v, signatures[i].r, signatures[i].s);
            uint256 validatorId = _getValidator(validator);
            if (validatorId == 0 || used[validatorId]) {
                continue;
            }
            used[validatorId] = true;
            counter ++;
        }
        if (counter < requiredSignatures) {
            revert NotEnoughValidSignatures(counter, requiredSignatures);
        }
        _release(IERC20(token), account, amount, externalId, feePool);
    }

    function getRequiredSignatures() public view returns (uint32) {
        return totalValidators() * threshold() / THRESHOLD_DIVIDER;
    }

    function addNative(uint256 maxAmount, uint8 foreignDecimals, FeeDef calldata feeDef, uint64 activatedTimestamp) public onlyOwner {
        TokenDef memory tokenDef = TokenDef(
            maxAmount,
            foreignDecimals,
            activatedTimestamp,
            FLAG_TOKEN_NATIVE,
            feeDef
        );
        _addToken(NATIVE_TOKEN, tokenDef);
        emit TokenAdd(NATIVE_TOKEN, _getToken(NATIVE_TOKEN));
    }

    function addToken(address token, uint256 maxAmount, uint8 foreignDecimals, bool isMintable, FeeDef memory feeDef, uint64 activatedTimestamp) public onlyOwner {
        TokenDef memory tokenDef = TokenDef(
            maxAmount,
            foreignDecimals,
            activatedTimestamp,
            isMintable ? FLAG_TOKEN_MINTABLE : 0,
            feeDef
        );

        _addToken(token, tokenDef);
        emit TokenAdd(token, _getToken(token));
    }

    function updateCommission(address token, FeeDef memory feeDef) public onlyOwner {
        _updateCommission(token, feeDef);
        emit TokenUpdated(token, _getToken(token));
    }

    function scheduleTokenToRemove(address token, uint64 removeTimestamp) public onlyOwner {
        _scheduleTokenToRemove(token, removeTimestamp);
        emit TokenUpdated(token, _getToken(token));
    }

    function removeToken(address token) public onlyOwner {
        if (_isUsed(IERC20(token))) {
            revert TokenInUse(token);
        }
        _removeToken(token);
        emit TokenRemove(token);
    }

    function addValidator(address account, uint16 id) public onlyOwner {
        if (totalValidators() >= MAX_VALIDATORS) {
            revert TooManuValidators(MAX_VALIDATORS);
        }
        _addValidator(account, id);
        emit ValidatorAdd(account);
    }

    function removeValidator(address account) public onlyOwner {
        _removeValidator(account);
        emit ValidatorRemove(account);
    }

    function setThreshold(uint32 threshold) public onlyOwner {
        _setThreshold(threshold);
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
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/BitMaps.sol)
pragma solidity ^0.8.0;

/**
 * @dev Library for managing uint256 to bool mapping in a compact and efficient way, providing the keys are sequential.
 * Largely inspired by Uniswap's https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol[merkle-distributor].
 */
library BitMaps {
    struct BitMap {
        mapping(uint256 => uint256) _data;
    }

    /**
     * @dev Returns whether the bit at `index` is set.
     */
    function get(BitMap storage bitmap, uint256 index) internal view returns (bool) {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        return bitmap._data[bucket] & mask != 0;
    }

    /**
     * @dev Sets the bit at `index` to the boolean `value`.
     */
    function setTo(
        BitMap storage bitmap,
        uint256 index,
        bool value
    ) internal {
        if (value) {
            set(bitmap, index);
        } else {
            unset(bitmap, index);
        }
    }

    /**
     * @dev Sets the bit at `index`.
     */
    function set(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] |= mask;
    }

    /**
     * @dev Unsets the bit at `index`.
     */
    function unset(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] &= ~mask;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/// Wrong exponent value.
error ExponentCannotBeZero();
error ExponentTooBig();
error ExponentTooSmall();

library ExpLib {
    /// The structure to hold exponent values. Good for percent and other.
    /// A precision is only uint32.
    /// The structure presents a value mantissa * 10 ** exponent.
    /// exponent might be negative
    struct Exp {
        uint32 mantissa;
        int8 exponent;
    }

    function check(Exp memory exp) internal pure {
        if (exp.exponent == 0) {
            revert ExponentCannotBeZero();
        }
        if (exp.exponent > 78) {
            revert ExponentTooBig();
        }
        if (exp.exponent < -78) {
            revert ExponentTooSmall();
        }
    }

    function isValid(Exp memory exp) internal pure returns (bool) {
        if (exp.exponent == 0) {
            return false;
        }
        if (exp.exponent > 78) {
            return false;
        }
        if (exp.exponent < -78) {
            return false;
        }
        return true;
    }

    function multiply(Exp storage exp, uint256 amount) internal view returns (uint256) {
        return multiply(amount, exp.mantissa, exp.exponent);
    }

    function multiply(Exp memory exp, uint256 amount) internal pure returns (uint256) {
        return multiply(amount, exp.mantissa, exp.exponent);
    }

    function multiply(uint256 amount, uint32 mantissa, int8 exponent) internal pure returns (uint256) {
        if (exponent == 0) {
            return amount;
        }
        uint256 prod = amount * mantissa;
        if (exponent > 0) {
            return prod * 10 ** uint8(exponent);
        }
        else {
            return prod / 10 ** uint8(-exponent);
        }
    }
}

// SPDX-License-Identifier: MS-LPL
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./IInitializer.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "./ILockerStorage.sol";
import "./ITokensRegister.sol";
import "./ITokensRegisterStorage.sol";
import "./IValidatorsRegisterStorage.sol";

/// Threshold value cannot be grater than divider.
/// @param maxValue maximum threshold value.
error TooBigThreshold(uint32 maxValue);
/// Threshold value cannot be less then 50%
/// @param minValue minimum threshold value.
error TooSmallThreshold(uint32 minValue);
/// Activation timestamp must be in future.
error ActivationInPast();

contract GatewayStorage is Context, Ownable, Initializable, IInitializer, ILockerStorage, ITokensRegisterStorage, IValidatorsRegisterStorage {
    uint32 public constant THRESHOLD_DIVIDER = 1000;
    // Gateway Storage
    bytes32 private _foreignChainId;
    uint64 private _activateTimestamp;
    uint32 private _threshold;

    // LockerStorage
    uint256 private _id;
    BitMaps.BitMap private _released;

    // TokensRegisterStorage
    mapping(address => ITokensRegister.TokenDef) private _tokens;

    // ValidatorsRegisterStorage
    mapping(address => uint256) internal _validators;
    BitMaps.BitMap internal _validatorIds;
    ValidatorsInfo internal _validatorsInfo;

    // GatewaysStorage, V2 fields
    address public feePool;

    constructor() {
        _disableInitializers();
    }

    function initialize(bytes32 foreignChainId_, uint64 activateTimestamp_, uint32 threshold_) initializer override external {
        if (activateTimestamp_ < block.timestamp) {
            revert ActivationInPast();
        }
        _foreignChainId = foreignChainId_;
        _activateTimestamp = activateTimestamp_;
        _setThreshold(threshold_);
        _transferOwnership(_msgSender());
    }

    function initialize2(address feePool_) reinitializer(2) override external {
        feePool = feePool_;
    }

    function foreignChainId() public view returns (bytes32) {
        return _foreignChainId;
    }

    function activateTimestamp() public view returns (uint64) {
        return _activateTimestamp;
    }

    function threshold() public view returns (uint32) {
        return _threshold;
    }

    function _setThreshold(uint32 threshold_) internal {
        if (threshold_ > THRESHOLD_DIVIDER) {
            revert TooBigThreshold(THRESHOLD_DIVIDER);
        }
        if (threshold_ < THRESHOLD_DIVIDER / 2) {
            revert TooSmallThreshold(THRESHOLD_DIVIDER / 2);
        }
        _threshold = threshold_;
    }

    function _incAndGet() internal override returns (uint256) {
        _id ++;
        return _id;
    }

    function lastId() public view returns (uint256) {
        return _id;
    }

    function _readReleased() internal view override returns (BitMaps.BitMap storage) {
        return _released;
    }

    function _readTokenDefinition(address account) internal view override returns (ITokensRegister.TokenDef storage tokenDef) {
        return _tokens[account];
    }

    function _writeTokenDefinition(address account, ITokensRegister.TokenDef memory tokenDef) internal override {
        _tokens[account] = tokenDef;
    }

    function _deleteTokenDefinition(address account) internal override {
        delete _tokens[account];
    }

    function _readValidator(address account) internal view override returns (uint256) {
        return _validators[account];
    }

    function _writeValidator(address account, uint256 id) internal override {
        _validators[account] = id;
    }

    function _deleteValidator(address account) internal override {
        delete _validators[account];
    }

    function _readValidatorIds() internal view override returns (BitMaps.BitMap storage) {
        return _validatorIds;
    }

    function _readValidatorsInfo() internal view override returns (ValidatorsInfo storage) {
        return _validatorsInfo;
    }

    function _writeValidatorsInfo(ValidatorsInfo memory info) internal override {
        _validatorsInfo = info;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

interface IBridgeERC20Token is IERC20Metadata {
    function mint(address to, uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IInitializer {
    function initialize(bytes32 foreignChainId_, uint64 activateTimestamp_, uint32 threshold_) external;
    function initialize2(address feePool_) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";

abstract contract ILockerStorage {
    function _incAndGet() internal virtual returns (uint256);
    function _readReleased() internal view virtual returns (BitMaps.BitMap storage);
}

// SPDX-License-Identifier: MS-LPL
pragma solidity ^0.8.0;
import "./ExpLib.sol";

abstract contract ITokensRegister {
    /// @notice Commission definition.
    struct FeeDef {
        /// Commission on lock funds.
        ExpLib.Exp lockFee;
        /// Commission on release funds.
        ExpLib.Exp releaseFee;
        /// Minimal amount of commission. Ignored if fee is explicitly defined as 0.
        uint256 minFeeAmount;
    }

    /// @notice Token definition.
    /// All fields are aligned on 256 bits word, the complete structure size = 3 * uint256
    struct TokenDef {
        /// A maximum possible total amount of the token to transfer.
        /// E.g if bridge has already transferred 1000 tokens, and maxAmount is 1100, then only 100 left.
        uint256 maxAmount;
        uint8 foreignDecimals;
        /// Timestamp when token will be available on the bridge
        /// if flag | FLAG_TOKEN_SCHEDULED_TO_REMOVE it also mean a date when it stop working for release
        uint64 activatedTimestamp;
        /// The token's flags
        uint104 flags;
        /// The token's commission definitions
        FeeDef commissions;
    }

    /// Token minted and burned on release and lock correspondingly.
    uint104 constant FLAG_TOKEN_MINTABLE = 1;
    /// It's a native token, e.g ETH for Ethereum
    uint104 constant FLAG_TOKEN_NATIVE = 2;
    /// Token was scheduled to remove, now activatedTimestamp means timestamp
    /// when release of these token will stop working
    uint104 constant FLAG_TOKEN_SCHEDULED_TO_REMOVE = 4;
    uint104 constant FLAG_MASK = FLAG_TOKEN_MINTABLE | FLAG_TOKEN_NATIVE | FLAG_TOKEN_SCHEDULED_TO_REMOVE;

    /// @notice Add token to the storage. The method does all possible checks before add.
    /// @notice
    function _addToken(address account, TokenDef memory definition) internal virtual;

    /// @notice Update commission parameters for the specified token.
    ///         The method does all possible checks before update.
    /// @param account Token account (address).
    /// @param feeDef Commission definition.
    function _updateCommission(address account, FeeDef memory feeDef) internal virtual;

    function _removeToken(address account) internal virtual;

    function _scheduleTokenToRemove(address account, uint64 removeTimestamp) internal virtual;

    function _getToken(address account) internal virtual view returns(TokenDef memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ITokensRegister.sol";

abstract contract ITokensRegisterStorage {
    function _readTokenDefinition(address account) internal view virtual returns (ITokensRegister.TokenDef storage tokenDef);
    function _writeTokenDefinition(address account, ITokensRegister.TokenDef memory tokenDef) internal virtual;
    function _deleteTokenDefinition(address account) internal virtual;
}

// SPDX-License-Identifier: MS-LPL
pragma solidity ^0.8.0;

abstract contract IValidatorsRegister {
    function _getValidator(address account) internal virtual returns (uint256);

    function _addValidator(address account, uint16 id) internal virtual returns (uint256);

    function _removeValidator(address account) internal virtual returns (uint256);

    function _getLastValidatorId() internal view virtual returns (uint64);

    function totalValidators() public view virtual returns (uint32);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/structs/BitMaps.sol";

abstract contract IValidatorsRegisterStorage {
    struct ValidatorsInfo {
        // supporting more than 1000 validators might lead to significant gas usage
        // this issue will be solved when validators migrate to TSS
        uint16 lastValidatorId;
        uint16 totalValidators;
    }

    function _readValidator(address account) internal view virtual returns (uint256);
    function _writeValidator(address account, uint256 id) internal virtual;
    function _deleteValidator(address account) internal virtual;
    function _readValidatorIds() internal view virtual returns (BitMaps.BitMap storage);
    function _readValidatorsInfo() internal view virtual returns (ValidatorsInfo storage);
    function _writeValidatorsInfo(ValidatorsInfo memory info) internal virtual;
}

// SPDX-License-Identifier: MS-LPL
pragma solidity ^0.8.18;

// Uncomment this line to use console.log
// import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "./ILockerStorage.sol";
import "./ITokensRegister.sol";
import "./IBridgeERC20Token.sol";
import "./ExpLib.sol";

/// The specified transfer already released.
/// @param externalId external transfer ID to release funds.
error DoubleSpending(uint64 externalId);
/// The specified token is not supported.
/// @param token token address.
error TokenNotSupported(address token);
/// The specified token has not been longer supported. It scheduled to remove, only release is possible.
/// @param token token address.
error TokenScheduledToRemove(address token);
/// The specified token is not yet activated.
/// @param token token address.
error TokenNotActivated(address token);
/// The specified amount is too small for the specified token.
/// @param token token address.
/// @param amount the specified amount of tokens to lock.
/// @param minValue minimal value for the specified token.
error TooSmallAmount(address token, uint256 amount, uint256 minValue);
/// The specified amount is too big for the specified token.
/// @param token token address.
/// @param amount the specified amount of tokens to lock.
/// @param maxValue maximum value for the specified token.
error TooBigAmount(address token, uint256 amount, uint256 maxValue);

abstract contract Locker is Context, ILockerStorage, ITokensRegister {
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Metadata;
    using ExpLib for ExpLib.Exp;
    using BitMaps for BitMaps.BitMap;

    event Lock(uint256 indexed id, address token, uint256 amount, bytes32 foreignAccount);
    event Release(uint256 indexed externalId, address token, uint256 amount, address to);

    function _lock(IERC20Metadata token,
                    address from,
                    uint256 amount,
                    bytes32 foreignAccount,
                    address feePool) internal returns(uint256) {
        TokenDef memory tokenDef = _getAndCheckToken(address(token), true);
        (uint256 rounded, ) = _roundCut(amount, token.decimals(), tokenDef.foreignDecimals);
        if (rounded == 0) {
            revert TooSmallAmount(address(token), amount, 10 ** tokenDef.foreignDecimals);
        }

        uint totalAmount = token.balanceOf(address(this)) + rounded;
        if (totalAmount > tokenDef.maxAmount) {
            revert TooBigAmount(address(token), amount, tokenDef.maxAmount);
        }

        uint256 fee = _feeCalculation(rounded, tokenDef.commissions.lockFee, tokenDef.commissions.minFeeAmount);
        if (fee >= rounded) {
            revert TooSmallAmount(address(token), amount, fee);
        }
        uint256 taxedAmount = rounded - fee;

        uint256 nextId = _incAndGet();
        if (tokenDef.flags & FLAG_TOKEN_MINTABLE != 0) {
            IBridgeERC20Token(address(token)).burnFrom(from, taxedAmount);
        }
        else {
            token.safeTransferFrom(from, address(this), taxedAmount);
        }

        if (fee > 0) {
            token.safeTransferFrom(from, feePool, fee);
        }

        emit Lock(nextId, address(token), taxedAmount, foreignAccount);
        return nextId;
    }

    function _lockEth(address nativeToken,
                        address from,
                        uint256 amount,
                        bytes32 foreignAccount,
                        address feePool) internal returns(uint256) {
        TokenDef memory tokenDef = _getAndCheckToken(address(nativeToken), true);
        (uint256 rounded, uint256 reminder) = _roundCut(amount, 18, tokenDef.foreignDecimals);
        if (rounded == 0) {
            revert TooSmallAmount(nativeToken, amount, 10**tokenDef.foreignDecimals);
        }

        uint totalAmount = address(this).balance + rounded;
        if (totalAmount > tokenDef.maxAmount) {
            revert TooBigAmount(nativeToken, amount, tokenDef.maxAmount);
        }

        uint256 fee = _feeCalculation(rounded, tokenDef.commissions.lockFee, tokenDef.commissions.minFeeAmount);
        if (fee >= rounded) {
            revert TooSmallAmount(nativeToken, amount, fee);
        }

        uint256 taxedAmount = rounded - fee;

        if (fee > 0) {
            payable(feePool).transfer(fee);
        }

        if (reminder > 0) {
            payable(from).transfer(reminder);
        }

        uint256 nextId = _incAndGet();
        emit Lock(nextId, address(nativeToken), taxedAmount, foreignAccount);
        return nextId;
    }

    function _release(IERC20 token,
                        address to,
                        uint256 amount,
                        uint64 externalId,
                        address feePool) internal {
        bool isReleased = _markReleased(externalId);
        if (!isReleased) {
            revert DoubleSpending(externalId);
        }
        TokenDef memory tokenDef = _getAndCheckToken(address(token), false);

        uint256 fee = _feeCalculation(amount, tokenDef.commissions.releaseFee, tokenDef.commissions.minFeeAmount);
        if (fee >= amount) {
            revert TooSmallAmount(address(token), amount, fee);
        }

        uint256 taxedAmount = amount - fee;

        if (tokenDef.flags & FLAG_TOKEN_NATIVE != 0) {
            payable(to).transfer(taxedAmount);
            if (fee > 0) {
                payable(feePool).transfer(fee);
            }
        }
        else if (tokenDef.flags & FLAG_TOKEN_MINTABLE != 0) {
            IBridgeERC20Token(address(token)).mint(to, taxedAmount);
            if (fee > 0) {
                IBridgeERC20Token(address(token)).mint(feePool, fee);
            }
        }
        else {
            token.safeTransfer(to, taxedAmount);
            if (fee > 0) {
                token.safeTransfer(feePool, fee);
            }
        }

        emit Release(externalId, address(token), amount, to);
    }

    function _getAndCheckToken(address token, bool isLock) private view returns(TokenDef memory) {
        TokenDef memory tokenDef = _getToken(address(token));
        if (tokenDef.maxAmount == 0) {
            revert TokenNotSupported(token);
        }
        bool scheduledToRemove = (tokenDef.flags & FLAG_TOKEN_SCHEDULED_TO_REMOVE != 0);
        if (isLock && scheduledToRemove) {
            revert TokenScheduledToRemove(token);
        }
        if (!scheduledToRemove && block.timestamp < tokenDef.activatedTimestamp) {
            revert TokenNotActivated(token);
        }
        if (scheduledToRemove && block.timestamp > tokenDef.activatedTimestamp) {
            revert TokenNotSupported(token);
        }
        return tokenDef;
    }

    function _isUsed(IERC20 token) internal view returns(bool) {
        TokenDef memory tokenDef = _getToken(address(token));
        if (tokenDef.flags & FLAG_TOKEN_NATIVE != 0) {
            return address(this).balance != 0;
        }
        if (tokenDef.flags & FLAG_TOKEN_MINTABLE != 0) {
            return token.totalSupply() != 0;
        }
        return token.balanceOf(address(this)) == 0;
    }

    /// This function rounds amount by the specified targetDecimals.
    /// Reminder goes to reminder.
    /// eg. decimals 4 (0.1234) to decimals 2 (0.00) = 0.1200, 0.0034
    function _roundCut(uint256 amount, uint8 sourceDecimals, uint8 targetDecimals) internal pure returns (uint256 value, uint256 reminder) {
        if (sourceDecimals <= targetDecimals) {
            return (amount, 0);
        }
        reminder = amount % 10**(sourceDecimals - targetDecimals);
        value = amount - reminder;
    }

    function _feeCalculation(uint256 amount, ExpLib.Exp memory exp, uint256 minFeeAmount) internal pure returns (uint256) {
        if (exp.mantissa == 0) {
            return 0;
        }

        uint256 fee = exp.multiply(amount);

        if (fee < minFeeAmount) {
            return minFeeAmount;
        }

        return fee;
    }

    function _markReleased(uint64 externalId) private returns (bool) {
        if (_readReleased().get(externalId)) {
            return false;
        }
        _readReleased().setTo(externalId, true);
        return true;
    }
}

// SPDX-License-Identifier: MS-LPL
pragma solidity ^0.8.0;

import "./ITokensRegister.sol";
import "./ITokensRegisterStorage.sol";

/// maxAmount value mustn't be zero.
error ZeroMaxAmount();
/// The specified token already exists.
/// @param token token address.
error TokenAlreadyExists(address token);
/// Token activation date must be in future.
error TokenActivationInPast();
/// The specified token does not exists.
/// @param token token address.
error TokenNotExists(address token);
/// The specified min fee amount is grater or equals than max amount.
error MinFeeAmountTooBig();
/// Lock fee is 100% or more.
error LockFeeTooBig();
/// Release fee is 100% or more.
error ReleaseFeeTooBig();

abstract contract TokensRegister is ITokensRegisterStorage, ITokensRegister {
    using ExpLib for ExpLib.Exp;

    function _addToken(address account, TokenDef memory definition) internal override {
        if (definition.maxAmount == 0) {
            revert ZeroMaxAmount();
        }
        if (definition.activatedTimestamp <= block.timestamp) {
            revert TokenActivationInPast();
        }
        TokenDef storage existing = _readTokenDefinition(account);
        if (existing.maxAmount != 0) {
            revert TokenAlreadyExists(account);
        }
        checkCommission(
            definition.maxAmount,
            definition.commissions
        );
        _writeTokenDefinition(account, definition);
    }

    function _updateCommission(address account, FeeDef memory feeDef) internal override {
        TokenDef storage definition = _readTokenDefinition(account);
        if (definition.maxAmount == 0) {
            revert TokenNotExists(account);
        }

        checkCommission(
            definition.maxAmount,
            feeDef
        );

        definition.commissions = feeDef;
    }

    function _scheduleTokenToRemove(address account, uint64 removeTimestamp) internal override {
        TokenDef storage definition = _readTokenDefinition(account);
        if (definition.maxAmount == 0) {
            revert TokenNotExists(account);
        }

        definition.flags |= FLAG_TOKEN_SCHEDULED_TO_REMOVE;
        definition.activatedTimestamp = removeTimestamp;
    }


    function _removeToken(address account) internal override {
        if (_readTokenDefinition(account).maxAmount == 0) {
            revert TokenNotExists(account);
        }
        _deleteTokenDefinition(account);
    }

    function _getToken(address account) internal override view returns(TokenDef memory) {
        return _readTokenDefinition(account);
    }

    function checkCommission(uint256 maxAmount, FeeDef memory feeDef) private pure {
        feeDef.lockFee.check();
        feeDef.releaseFee.check();

        if (feeDef.minFeeAmount > maxAmount) {
            revert MinFeeAmountTooBig();
        }

        uint256 feeOfOne = feeDef.lockFee.multiply(1);
        if (feeOfOne != 0) {
            revert LockFeeTooBig();
        }

        feeOfOne = feeDef.releaseFee.multiply(1);
        if (feeOfOne != 0) {
            revert ReleaseFeeTooBig();
        }

        // check possible overflows
        feeDef.lockFee.multiply(maxAmount);
        feeDef.releaseFee.multiply(maxAmount);
    }
}

// SPDX-License-Identifier: MS-LPL
pragma solidity ^0.8.0;

import "./IValidatorsRegister.sol";
import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "./IValidatorsRegisterStorage.sol";

/// The specified validator id is too small. It must be grater than zero.
error ValidatorIdTooSmall();
/// The validator with the specified account already exists.
/// @param account The validator address.
error ValidatorAlreadyExists(address account);
/// The specified validator id is already occupied.
/// @param id The validator id.
error ValidatorIdOccupied(uint16 id);
/// The specified validator account does not exists.
/// @param account The validator address.
error ValidatorNotExists(address account);

abstract contract ValidatorsRegister is IValidatorsRegisterStorage, IValidatorsRegister {
    using BitMaps for BitMaps.BitMap;

    function _getValidator(address account) internal override view returns (uint256) {
        return _readValidator(account);
    }

    function _addValidator(address account, uint16 id) internal override returns (uint256) {
        if (id == 0) {
            revert ValidatorIdTooSmall();
        }
        if (_readValidator(account) != 0) {
            revert ValidatorAlreadyExists(account);
        }
        if (_readValidatorIds().get(id)) {
            revert ValidatorIdOccupied(id);
        }
        ValidatorsInfo memory info = _readValidatorsInfo();
        info.totalValidators ++;
        if (id > info.lastValidatorId) {
            info.lastValidatorId = id;
        }
        _writeValidatorsInfo(info);
        _writeValidator(account, id);
        _readValidatorIds().setTo(id, true);
        return info.lastValidatorId;
    }

    function _removeValidator(address account) internal override returns (uint256) {
        uint256 id = _readValidator(account);
        if (id == 0) {
            revert ValidatorNotExists(account);
        }
        _deleteValidator(account);
        _readValidatorsInfo().totalValidators --;
        _readValidatorIds().setTo(id, false);
        return id;
    }

    function _getLastValidatorId() internal view override returns (uint64) {
        return _readValidatorsInfo().lastValidatorId;
    }

    function totalValidators() public view override returns (uint32) {
        return _readValidatorsInfo().totalValidators;
    }
}