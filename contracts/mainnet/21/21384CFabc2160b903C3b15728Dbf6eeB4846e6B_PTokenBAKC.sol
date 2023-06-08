// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./PToken.sol";
import "./interfaces/IApeStaking.sol";

/**
 * @title Pawnfi's PTokenBAKC Contract
 * @author Pawnfi
 */
contract PTokenBAKC is PToken {
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    // bytes32(uint256(keccak256('eip1967.proxy.stakeDelegate')) - 1))
    bytes32 private constant _STAKE_DELEGATE_SLOT = 0xb8eef20a3eb5434ad680459d96ef6f313aea93fa19e616f4755d155d7b1b3810;

    /**
     * @notice set ApeStaking contract address
     * @param stakeDelegate ApeStaking address
     */
    function setStakeDelegate(address stakeDelegate) public virtual {
        require(IOwnable(factory).owner() == msg.sender, "Caller isn't owner");
        require(
            AddressUpgradeable.isContract(stakeDelegate),
            "PTokenBAKC: stakeDelegate is not a contract"
        );
        bytes32 slot = _STAKE_DELEGATE_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, stakeDelegate)
        }
    }

    /**
     * @notice get ApeStaking contract address
     * @return stakeDelegate ApeStaking address
     */
    function getStakeDelegate() public view virtual returns (address stakeDelegate) {
        bytes32 slot = _STAKE_DELEGATE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            stakeDelegate := sload(slot)
        }
    }

    /**
     * @notice get P-BAYC contract address
     * @return address P-BAYC address
     */
    function getPTokenBAYC() public view virtual returns (address) {
        return IApeStaking(getStakeDelegate()).pbaycAddr();
    }

    /**
     * @notice get P-MAYC contract address
     * @return address P-MAYC address
     */
    function getPTokenMAYC() public view virtual returns (address) {
        return IApeStaking(getStakeDelegate()).pmaycAddr();
    }

    /**
     * @notice get nft id depositor
     * @param nftId nft id
     * @return address nft id depositor address
     */
    function getNftOwner(uint256 nftId) external view virtual returns(address) {
        return _allInfo[nftId].endBlock > 0 ? _allInfo[nftId].userAddr : address(0);
    }

    /**
     * @notice flash loan nft
     * @param receipient nft receiver and deal loaned nft
     * @param nftIds nft id list
     * @param data calldata
     */
    function flashLoan(address receipient, uint256[] calldata nftIds, bytes memory data) external virtual nonReentrant {
        require(msg.sender == getPTokenBAYC() || msg.sender == getPTokenMAYC(), "Caller is not P-BAYC/P-MAYC address");
        // 1, transfer BAKC to ptokenBAYC or ptokenMAYC
        for (uint256 i = 0; i < nftIds.length; i++) {
            TransferHelper.transferOutNonFungibleToken(IPTokenFactory(factory).nftTransferManager(), nftAddress, address(this), receipient, nftIds[i]);
        }
        
        // 2, use loaned bakc
        IPTokeCall(receipient).pTokenCall(nftIds, data);
        
        // 3, transfer BAKC back from ptokenBAYC or ptokenMAYC
        for (uint256 i = 0; i < nftIds.length; i++) {
            TransferHelper.transferInNonFungibleToken(IPTokenFactory(factory).nftTransferManager(), nftAddress, receipient, address(this), nftIds[i]);
        }
    }

    /**
     * @dev See {PToken-specificTrade}.
     */
    function specificTrade(uint256[] memory nftIds) public virtual override {
        IApeStaking(getStakeDelegate()).onStopStake(msg.sender, nftAddress, nftIds, IApeStaking.RewardAction.ONREDEEM);
        super.specificTrade(nftIds);
    }

    /**
     * @dev See {PToken-withdraw}.
     */
    function withdraw(uint256[] memory nftIds) public virtual override returns (uint256 tokenAmount) {
        IApeStaking(getStakeDelegate()).onStopStake(msg.sender, nftAddress, nftIds, IApeStaking.RewardAction.ONWITHDRAW);
        return super.withdraw(nftIds);
    }

    /**
     * @dev See {PToken-convert}.
     */
    function convert(uint256[] memory nftIds) public virtual override {
        IApeStaking(getStakeDelegate()).onStopStake(msg.sender, nftAddress, nftIds, IApeStaking.RewardAction.ONWITHDRAW);
        super.convert(nftIds);
    }
}

interface IPTokeCall {
    function pTokenCall(uint256[] calldata nftIds, bytes memory data) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
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
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
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
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal onlyInitializing {
    }

    function __ERC721Holder_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

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
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSetUpgradeable {
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
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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
     * @dev Returns the number of values in the set. O(1).
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IApeCoinStaking {
    struct PairNft {
        uint128 mainTokenId;
        uint128 bakcTokenId;
    }

    struct PairNftDepositWithAmount {
        uint32 mainTokenId;
        uint32 bakcTokenId;
        uint184 amount;
    }

    struct SingleNft {
        uint32 tokenId;
        uint224 amount;
    }

    struct DashboardStake {
        uint256 poolId;
        uint256 tokenId;
        uint256 deposited;
        uint256 unclaimed;
        uint256 rewards24hr;
        DashboardPair pair;
    }

    struct DashboardPair {
        uint256 mainTokenId;
        uint256 mainTypePoolId;
    }

    struct PoolUI {
        uint256 poolId;
        uint256 stakedAmount;
        TimeRange currentTimeRange;
    }

    struct TimeRange {
        uint48 startTimestampHour;
        uint48 endTimestampHour;
        uint96 rewardsPerHour;
        uint96 capPerPosition;
    }

    struct PairNftWithdrawWithAmount {
        uint32 mainTokenId;
        uint32 bakcTokenId;
        uint184 amount;
        bool isUncommit;
    }
    /// @dev Per address amount and reward tracking
    struct Position {
        uint256 stakedAmount;
        int256 rewardsDebt;
    }
        /// @notice State for ApeCoin, BAYC, MAYC, and Pair Pools
    struct Pool {
        uint48 lastRewardedTimestampHour;
        uint16 lastRewardsRangeIndex;
        uint96 stakedAmount;
        uint96 accumulatedRewardsPerShare;
        TimeRange[] timeRanges;
    }
    function addressPosition(address)
        external
        view
        returns (uint256 stakedAmount, int256 rewardsDebt);

    function apeCoin() external view returns (address);

    function bakcToMain(uint256, uint256)
        external
        view
        returns (uint248 tokenId, bool isPaired);

    function claimApeCoin(address _recipient) external;

    function claimBAKC(
        PairNft[] memory _baycPairs,
        PairNft[] memory _maycPairs,
        address _recipient
    ) external;

    function claimBAYC(uint256[] memory _nfts, address _recipient) external;

    function claimMAYC(uint256[] memory _nfts, address _recipient) external;

    function claimSelfApeCoin() external;

    function claimSelfBAKC(
        PairNft[] memory _baycPairs,
        PairNft[] memory _maycPairs
    ) external;

    function claimSelfBAYC(uint256[] memory _nfts) external;

    function claimSelfMAYC(uint256[] memory _nfts) external;

    function depositApeCoin(uint256 _amount, address _recipient) external;

    function depositBAKC(
        PairNftDepositWithAmount[] memory _baycPairs,
        PairNftDepositWithAmount[] memory _maycPairs
    ) external;

    function depositBAYC(SingleNft[] memory _nfts) external;

    function depositMAYC(SingleNft[] memory _nfts) external;

    function depositSelfApeCoin(uint256 _amount) external;

    function getAllStakes(address _address)
        external
        view
        returns (DashboardStake[] memory);

    function getApeCoinStake(address _address)
        external
        view
        returns (DashboardStake memory);

    function getBakcStakes(address _address)
        external
        view
        returns (DashboardStake[] memory);

    function getBaycStakes(address _address)
        external
        view
        returns (DashboardStake[] memory);

    function getMaycStakes(address _address)
        external
        view
        returns (DashboardStake[] memory);

    function getPoolsUI()
        external
        view
        returns (
            PoolUI memory,
            PoolUI memory,
            PoolUI memory,
            PoolUI memory
        );

    function getSplitStakes(address _address)
        external
        view
        returns (DashboardStake[] memory);

    function getTimeRangeBy(uint256 _poolId, uint256 _index)
        external
        view
        returns (TimeRange memory);

    function mainToBakc(uint256, uint256)
        external
        view
        returns (uint248 tokenId, bool isPaired);

    function nftContracts(uint256) external view returns (address);

    function nftPosition(uint256, uint256)
        external
        view
        returns (uint256 stakedAmount, int256 rewardsDebt);

    function pendingRewards(
        uint256 _poolId,
        address _address,
        uint256 _tokenId
    ) external view returns (uint256);

    function pools(uint256)
        external
        view
        returns (
            uint48 lastRewardedTimestampHour,
            uint16 lastRewardsRangeIndex,
            uint96 stakedAmount,
            uint96 accumulatedRewardsPerShare
        );

    function removeLastTimeRange(uint256 _poolId) external;

    function renounceOwnership() external;

    function rewardsBy(
        uint256 _poolId,
        uint256 _from,
        uint256 _to
    ) external view returns (uint256, uint256);

    function stakedTotal(address _address) external view returns (uint256);

    function updatePool(uint256 _poolId) external;

    function withdrawApeCoin(uint256 _amount, address _recipient) external;

    function withdrawBAKC(
        PairNftWithdrawWithAmount[] memory _baycPairs,
        PairNftWithdrawWithAmount[] memory _maycPairs
    ) external;

    function withdrawBAYC(
        SingleNft[] memory _nfts,
        address _recipient
    ) external;

    function withdrawMAYC(
        SingleNft[] memory _nfts,
        address _recipient
    ) external;

    function withdrawSelfApeCoin(uint256 _amount) external;

    function withdrawSelfBAYC(SingleNft[] memory _nfts) external;

    function withdrawSelfMAYC(SingleNft[] memory _nfts) external;
}

// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.6.6. SEE SOURCE BELOW. !!
pragma solidity ^0.8.4;

import "./IApeCoinStaking.sol";

interface IApeStaking {
    struct StakingInfo {
        address nftAsset;
        uint256 cashAmount;
        uint256 borrowAmount;
    }

    struct DepositInfo {
        uint256[] mainTokenIds;
        uint256[] bakcTokenIds;
    }

    event ClaimPairNft(
        address userAddr,
        address nftAsset,
        uint256 mainTokenId,
        uint256 bakcTokenId,
        uint256 rewardAmount
    );
    event ClaimSingleNft(
        address userAddr,
        address nftAsset,
        uint256 nftId,
        uint256 rewardAmount
    );
    event DepositNftToStake(
        address userAddr,
        address nftAsset,
        uint256[] nftIds,
        uint256 iTokenAmount,
        uint256 ptokenAmount
    );
    event Initialized(uint8 version);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event StakePairNft(
        address userAddr,
        address nftAsset,
        uint256 mainTokenId,
        uint256 bakcTokenId,
        uint256 amount
    );
    event StakeSingleNft(
        address userAddr,
        address nftAsset,
        uint256 nftId,
        uint256 amount
    );
    event UnstakePairNft(
        address userAddr,
        address nftAsset,
        uint256 mainTokenId,
        uint256 bakcTokenId,
        uint256 amount,
        uint256 rewardAmount
    );
    event UnstakeSingleNft(
        address userAddr,
        address nftAsset,
        uint256 nftId,
        uint256 amount,
        uint256 rewardAmount
    );
    event WithdrawNftFromStake(
        address userAddr,
        address nftAsset,
        uint256 nftId,
        uint256 iTokenAmount,
        uint256 ptokenAmount
    );

    enum RewardAction { 
        CLAIM, 
        WITHDRAW,
        REDEEM,
        RESTAKE,
        STOPSTAKE,
        ONWITHDRAW,
        ONREDEEM
    }

    function apeCoin() external view returns (address);

    function apeCoinStaking() external view returns (address);

    function apePool() external view returns (address);

    function bakcAddr() external view returns (address);

    function baycAddr() external view returns (address);

    function borrowApeAndStake(
        StakingInfo memory stakingInfo,
        IApeCoinStaking.SingleNft[] memory _nfts,
        IApeCoinStaking.PairNftDepositWithAmount[] memory _nftPairs
    ) external;

    function claimAndRestake(
        address userAddr,
        uint256[] memory baycNfts,
        uint256[] memory maycNfts,
        IApeCoinStaking.PairNft[] memory baycPairNfts,
        IApeCoinStaking.PairNft[] memory maycPairNfts
    ) external;

    function claimApeCoin(address nftAsset, uint256[] memory _nfts) external;

    function claimBAKC(
        address nftAsset,
        IApeCoinStaking.PairNft[] memory _nftPairs
    ) external;

    function depositAndBorrowApeAndStake(
        DepositInfo memory depositInfo,
        StakingInfo memory stakingInfo,
        IApeCoinStaking.SingleNft[] memory _nfts,
        IApeCoinStaking.PairNftDepositWithAmount[] memory _nftPairs
    ) external;

    function feeTo() external view returns (address);

    function getPTokenStaking(address nftAsset)
        external
        view
        returns (address ptokenStaking);

    function getRewardRatePerBlock(uint256 poolId, uint256 addAmount)
        external
        view
        returns (uint256);

    function getStakeNftIds(address nftAsset)
        external
        view
        returns (uint256[] memory nftIds);

    function getUserHealth(address userAddr)
        external
        returns (uint256 totalIncome, uint256 totalPay);

    function getUserInfo(address userAddr, address nftAsset)
        external
        returns (
            uint256 collectRate,
            uint256 iTokenAmount,
            uint256 pTokenAmount,
            uint256 interestReward,
            uint256[] memory stakeNftIds,
            uint256[] memory depositNftIds
        );

    function initialize(
        address apeCoinStaking_,
        address apePool_,
        address nftGateway_,
        address pTokenFactory_,
        address pawnToken_,
        address feeTo_,
        ApeStakingStorage.StakingConfiguration memory stakingConfiguration_
    ) external;

    function maycAddr() external view returns (address);

    function nftGateway() external view returns (address);

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external returns (bytes4);

    function onStopStake(
        address caller,
        address nftAsset,
        uint256[] memory nftIds,
        RewardAction actionType
    ) external;

    function owner() external view returns (address);

    function pawnToken() external view returns (address);

    function pbakcAddr() external view returns (address);

    function pbaycAddr() external view returns (address);

    function pmaycAddr() external view returns (address);

    function renounceOwnership() external;

    function setCollectRate(uint256 newCollectRate) external;

    function setFeeTo(address newFeeTo) external;

    function setStakingConfiguration(
        ApeStakingStorage.StakingConfiguration memory newStakingConfiguration
    ) external;

    function stakingConfiguration()
        external
        view
        returns (
            uint256 addMinStakingRate,
            uint256 restakeMinTotalAmount,
            uint256 restakeMinOneAmount,
            uint256 liquidateRate,
            uint256 borrowSafeRate,
            uint256 liquidatePawnAmount,
            uint256 feeRate
        );

    function transferOwnership(address newOwner) external;

    function unstakeAndRepay(
        address userAddr,
        address[] memory nftAssets,
        uint256[] memory nftIds
    ) external;

    function withdraw(
        uint256[] memory _baycTokenIds,
        uint256[] memory _maycTokenIds,
        uint256[] memory _bakcTokenIds
    ) external;

    function withdrawApeCoin(
        address nftAsset,
        IApeCoinStaking.SingleNft[] memory _nfts
    ) external;

    function withdrawBAKC(
        address nftAsset,
        IApeCoinStaking.PairNftWithdrawWithAmount[] memory _nftPairs
    ) external;
}

interface ApeStakingStorage {
    struct StakingConfiguration {
        uint256 addMinStakingRate;
        uint256 restakeMinTotalAmount;
        uint256 restakeMinOneAmount;
        uint256 liquidateRate;
        uint256 borrowSafeRate;
        uint256 liquidatePawnAmount;
        uint256 feeRate;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface INftController {

    /**
     * @notice Ptoken <> NFT configuration
     * @member randFeeRate The fee rate for exchanging ptoken for random nft
     * @member noRandFeeRate The fee rate for exchanging ptoken for specific nft
     */
    struct ConfigInfo {
        uint256 randFeeRate;
        uint256 noRandFeeRate;
    }

    /**
     * @notice NFT staking status
     * @member FREEDOM Free state - can be exchanged by ptoken
     * @member STAKING Staked state - can only be redeemed until duration ends
     */
    enum Action { FREEDOM, STAKING }

    /*** User Interface ***/
    function STAKER_ROLE() external view returns(bytes32);
    function pieceCount() external view returns(uint256);
    function randomTool() external view returns(address);
    function openControl() external view returns(bool);
    function whitelist(address) external view returns(bool);
    function nftBlackList(address) external view returns(bool);
    function nftIdBlackList(address, uint256) external view returns(bool);
    function configInfo() external view returns (uint256 randFeeRate, uint256 noRandFeeRate);
    function enableConfig(address nftAddr) external view returns(bool);
    function nftConfigInfo(address nftAddr) external view returns (uint256 randFeeRate, uint256 noRandFeeRate);
    function getFeeInfo(address nftAddr) external view returns(uint256 randFee, uint256 noRandFee);
    function getRandoms(address nftAddr, uint256 rangeMaximum) external returns(uint256);
    function supportedNft(address nftAddr) external view returns(bool);
    function supportedNftId(address operator, address nftAddr, uint256 nftId, Action action) external view returns(bool);

    /*** Admin Functions ***/
    function updateRandomTool(address _randomTool) external;
    function updateConfigInfo(ConfigInfo memory configInfo_) external;
    function updateNftConfigInfo(address nftAddr, ConfigInfo memory nftConfigInfo_) external;
    function setNftBlackList(address nftAddr, bool harmful) external;
    function setNftIdBlackList(address nftAddr, uint256 nftId, bool harmful) external;
    function batchSetNftIdBlackList(address nftAddr, uint256[] calldata nftIds, bool harmful) external;
    function setOpenControl(bool newOpenControl) external;
    function setWhitelist(address nftAddr, bool isAllow) external;
    function batchSetWhitelist(address[] calldata nftAddrs, bool isAllow) external;    
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "./INftController.sol";

interface IPToken {

    /**
     * @notice NFT staking info
     * @member startBlock The block height when exchanging NFT for ptoken
     * @member endBlock Endning block height of staking deadline
     * @member userAddr User address
     * @member action The method of staking NFT - can either be exchanged or redeemed
     */
    struct NftInfo {
        uint256 startBlock;
        uint256 endBlock;
        address userAddr;
        INftController.Action action;
    }

    /// @notice Emitted when swap random NFT
    event RandomTrade(address indexed recipient, uint256 nftIdCount, uint256 totalFee, uint256[] nftIds);

    /// @notice Emitted when swap specific NFT
    event SpecificTrade(address indexed recipient, uint256 nftIdCount, uint256 totalFee, uint256[] nftIds);

    /// @notice Emitted when swap ptoken or deposit NFT
    event Deposit(address indexed operator, uint256[] nftIds, uint256 blockNumber);

    /// @notice Emitted when withdraw deposited (locked) NFT
    event Withdraw(address indexed operator, uint256[] nftIds);

    /// @notice Emitted when leveraged NFT is liquidated - status changed to exchangeable
    event Convert(address indexed operator, uint256[] nfts);

    /*** User Interface ***/
    function factory() external view returns(address);
    function nftAddress() external view returns(address);
    function pieceCount() external view returns(uint256);
    function DOMAIN_SEPARATOR() external view returns(bytes32);
    function nonces(address) external view returns(uint256);
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    function randomTrade(uint256 nftIdCount) external returns(uint256[] memory nftIds);
    function specificTrade(uint256[] memory nftIds) external;
    function deposit(uint256[] memory nftIds) external returns(uint256 tokenAmount);
    function deposit(uint256[] memory nftIds, uint256 blockNumber) external returns(uint256 tokenAmount);
    function withdraw(uint256[] memory nftIds) external returns(uint256 tokenAmount);
    function convert(uint256[] memory nftIds) external;
    function getRandNftCount() external view returns(uint256);
    function getNftInfo(uint256 nftId) external view returns (NftInfo memory);
    function getRandNft(uint256 _tokenIndex) external view returns (uint256);
    function getNftController() external view returns(INftController);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

interface IPTokenFactory {
    
    /*** User Interface ***/
    function feeTo() external view returns(address);
    function beacon() external view returns(address);
    function controller() external view returns(address);
    function nftTransferManager() external view returns(address);
    function allNFTsLength() external view returns(uint256);
    function allNFTs(uint256 index) external view returns(address);
    function getNftAddress(address ptokenAddr) external view returns(address);
    function getPiece(address nftAddr) external view returns(address);
    function parameters() external view returns (address, bytes memory);
    function createPiece(address nftAddr) external returns(address pieceTokenAddr);

    /*** Admin Functions ***/
    function setFeeTo(address feeTo_) external;
}

interface IOwnable {
    function owner() external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

interface ITransferManager {
    function getInputData(address nftAddress, address from, address to, uint256 tokenId, bytes32 operateType) external view returns (bytes memory data);
}

library TransferHelper {

    using AddressUpgradeable for address;

    // keccak256("TRANSFER_IN")
    bytes32 private constant TRANSFER_IN = 0xe69a0828d85fdb5875ad77f7b8a0e2275447a64f18daaf58f34b3af9b7b691da;
    // keccak256("TRANSFER_OUT")
    bytes32 private constant TRANSFER_OUT = 0x2b6780fa84213a97faf5c6208861692a9b75df0c4afffad07a2dc98411dfe785;
    // keccak256("APPROVAL")
    bytes32 private constant APPROVAL = 0x2acd155ba8c67e9321668716d05aae1ff9e47e502b6b2f301b6f41e3a57ee2ef;

    /**
     * @notice Transfer in NFT
     * @param transferManager nft transfer manager contract address
     * @param nftAddr nft address
     * @param from Sender address
     * @param to Receiver address
     * @param nftId NFT ID   
     */
    function transferInNonFungibleToken(address transferManager, address nftAddr, address from, address to, uint256 nftId) internal {
        bytes memory data = ITransferManager(transferManager).getInputData(nftAddr, from, to, nftId, TRANSFER_IN);
        nftAddr.functionCall(data);
    }

    /**
     * @notice Transfer in NFT
     * @param transferManager nft transfer manager contract address
     * @param nftAddr nft address
     * @param from Sender address
     * @param to Receiver address
     * @param nftId NFT ID   
     */
    function transferOutNonFungibleToken(address transferManager, address nftAddr, address from, address to, uint256 nftId) internal {
        bytes memory data = ITransferManager(transferManager).getInputData(nftAddr, from, to, nftId, TRANSFER_OUT);
        nftAddr.functionCall(data);
    }

    /**
     * @notice Approve NFT
     * @param transferManager nft transfer manager contract address
     * @param nftAddr nft address
     * @param from Sender address
     * @param to Receiver address
     * @param nftId NFT ID   
     */
    function approveNonFungibleToken(address transferManager, address nftAddr, address from, address to, uint256 nftId) internal {
        bytes memory data = ITransferManager(transferManager).getInputData(nftAddr, from, to, nftId, APPROVAL);
        nftAddr.functionCall(data);
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";
import "./interfaces/IPTokenFactory.sol";
import "./libraries/TransferHelper.sol";
import "./PTokenStorage.sol";

/**
 * @title ptoken contract
 * @notice Supports NFT fractionalization, redemption, etc.
 * @author Pawnfi
 */
contract PToken is ERC20Upgradeable, ERC721HolderUpgradeable, ReentrancyGuardUpgradeable, PTokenStorage {
    using SafeMathUpgradeable for uint256;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    /**
     * @notice Initialize contract
     * @param nftAddress_ NFT address
     */    
    function initialize(address nftAddress_) external initializer {
        __ERC20_init(
            string(abi.encodePacked("Pawnfi ", IERC721MetadataUpgradeable(nftAddress_).name())),
            string(abi.encodePacked("P-", IERC721MetadataUpgradeable(nftAddress_).symbol()))
        );
        __ERC721Holder_init();
        __ReentrancyGuard_init();
        factory = msg.sender;
        nftAddress = nftAddress_;
        pieceCount = INftController(IPTokenFactory(msg.sender).controller()).pieceCount();

        uint chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name())),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
    }

    /**
     * @notice EIP712 signature authorization method
     * @param owner Initiator address
     * @param spender Recipient address
     * @param value token amount
     * @param deadline The deadline
     * @param v Derived from signature information
     * @param r Derived from signature information
     * @param s Derived from signature information   
     */
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external virtual override {
        require(deadline >= block.timestamp, 'EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }

    /**
     * @notice Deposit (lock) Nft
     * @param nftIds nft list
     * @return tokenAmount ptoken amount
     */
    function deposit(uint256[] memory nftIds) external virtual override returns (uint256 tokenAmount) {
        return deposit(nftIds, 0);
    }

    /**
     * @notice Deposit (lock) Nft
     * @dev blockNumber = 0，Nft can be randomly swapped，blockNumber > 0, only within current block > blockNumber, can be specifically swapped
     * @param nftIds nft list
     * @param blockNumber The block height at which the lock-up expires
     * @return tokenAmount ptoken amount
     */
    function deposit(uint256[] memory nftIds, uint256 blockNumber) public virtual override nonReentrant returns (uint256 tokenAmount) {
        address msgSender = msg.sender;
        uint256 length = nftIds.length;
        require(length > 0, "SIZE ERR");
        address nftAddr = nftAddress;

        for(uint256 i = 0; i < length; i++) {
            uint256 nftId = nftIds[i];
            INftController.Action action = INftController.Action.STAKING;
            if(blockNumber == 0) {
                action = INftController.Action.FREEDOM;
                _allRandID.add(nftId);
            }
            require(getNftController().supportedNftId(msgSender, nftAddr, nftId, action), 'ID NOT ALLOW');

            NftInfo memory nftInfo = getNftInfo(nftId);
            nftInfo.startBlock = block.number;
            nftInfo.endBlock = blockNumber;
            nftInfo.userAddr = msgSender;
            nftInfo.action = action;
            TransferHelper.transferInNonFungibleToken(IPTokenFactory(factory).nftTransferManager(), nftAddress, msgSender, address(this), nftId);
            _allInfo[nftId] = nftInfo;
        }

        tokenAmount = pieceCount.mul(length);
        _mint(msgSender, tokenAmount);
        emit Deposit(msgSender, nftIds, blockNumber);
    }

    /**
     * @notice ptoken swap random NFT
     * @param nftIdCount NFT amount
     * @return nftIds nftId list
     */
    function randomTrade(uint256 nftIdCount) public virtual override nonReentrant returns (uint256[] memory nftIds) {
        address msgSender = msg.sender;
        address nftAddr = nftAddress;
        require(nftIdCount > 0 && nftIdCount <= getRandNftCount(), 'NO ID');

        INftController nftController = getNftController();
        (uint256 randFee, ) = nftController.getFeeInfo(nftAddr);
        uint256 fee = _collectFee(msgSender, randFee, nftIdCount);

        nftIds = new uint256[](nftIdCount);

        for(uint256 i = 0; i < nftIdCount; i++) {
            uint256 tokenIndex = nftController.getRandoms(nftAddr, getRandNftCount());
            uint256 nftId = getRandNft(tokenIndex);
            _tradeCore(nftId, msgSender);
            nftIds[i] = nftId;
        }
        emit RandomTrade(msgSender, nftIdCount, fee, nftIds);
        return nftIds;
    }

    /**
     * @notice ptoken swap specific NFT
     * @param nftIds nftId list
     */
    function specificTrade(uint256[] memory nftIds) public virtual override nonReentrant {
        address msgSender = msg.sender;
        uint256 nftIdCount = nftIds.length;
        require(nftIdCount > 0, 'SIZE ERR');
        (, uint256 noRandFee) = getNftController().getFeeInfo(nftAddress);
        uint256 fee = _collectFee(msgSender, noRandFee, nftIdCount);

        for(uint i = 0; i < nftIdCount; i++) {
            uint256 nftId = nftIds[i];
            _tradeCore(nftId, msgSender);
        }
        emit SpecificTrade(msgSender, nftIds.length, fee, nftIds);
    }

    function _tradeCore(uint256 nftId, address sender) internal {
        NftInfo memory nftInfo = getNftInfo(nftId);
        if(nftInfo.action == INftController.Action.FREEDOM) {
            require(_allRandID.remove(nftId), "nftId is not in the random list");
        } else {
            require(nftInfo.endBlock < block.number,'STATUS ERR');
        }
        _delData(nftId, sender);
    }

    /**
     * @notice Charge swap fee
     * @param sender Sender
     * @param fee Swap fee for one NFT
     * @param nftIdCount nftId amount
     */
    function _collectFee(address sender, uint256 fee, uint256 nftIdCount) internal returns (uint256) {
        uint256 tokenAmount = pieceCount.mul(nftIdCount);
        uint256 totalFee = fee.mul(nftIdCount);//Calculate the fees of NFTs

        _transfer(sender, address(this), tokenAmount.add(totalFee));
        _burn(address(this), tokenAmount);
        _transfer(address(this), IPTokenFactory(factory).feeTo(), totalFee); //Transfer out fees
        return totalFee;
    }

    /**
     * @notice Withdraw locked Nft
     * @param nftIds nftId list
     * @return tokenAmount token amount
     */
    function withdraw(uint256[] memory nftIds) public virtual override nonReentrant returns (uint256 tokenAmount) {
        address msgSender = msg.sender;
        uint256 length = nftIds.length;
        require(length > 0, "SIZE ERR");

        tokenAmount = pieceCount.mul(length);
        _burn(msgSender, tokenAmount);

        for(uint256 i = 0; i < length; i++) {
            uint256 nftId = nftIds[i];
            NftInfo memory nftInfo = getNftInfo(nftId);
            require(nftInfo.userAddr == msgSender, 'USER NOT ALLOW');//Must be lock initiator
            require(nftInfo.startBlock < block.number, "prohibit same block operate");
            require(nftInfo.action == INftController.Action.STAKING && nftInfo.endBlock >= block.number, "Status error");

            _delData(nftId, msgSender);
        }
        emit Withdraw(msgSender, nftIds);
    }

    /**
     * @notice Transfer NFT to receiver
     * @param nftId nftId
     * @param receipient Receiver
     */
    function _delData(uint256 nftId, address receipient) internal {
        delete _allInfo[nftId];
        TransferHelper.transferOutNonFungibleToken(IPTokenFactory(factory).nftTransferManager(), nftAddress, address(this), receipient, nftId);
    }

    /**
     * @notice Release locked NFT
     * @dev nft status from Staking to Free
     * @param nftIds nftId list
     */
    function convert(uint256[] memory nftIds) public virtual override nonReentrant {
        for(uint256 i = 0; i < nftIds.length; i++) {
            uint256 nftId = nftIds[i];
            NftInfo memory lockInfo = getNftInfo(nftId);
            require(lockInfo.userAddr == msg.sender, 'USER NOT ALLOW');//Must be lock initiator
            require(lockInfo.action == INftController.Action.STAKING, "Status error");
            lockInfo.action = INftController.Action.FREEDOM;
            _allInfo[nftId] = lockInfo;
            _allRandID.add(nftId);
        }
        emit Convert(msg.sender, nftIds);
    }
 
    /**
     * @notice Get deposited NFT information
     * @param nftId nftId
     * @return NftInfo Nft Info
     */
    function getNftInfo(uint256 nftId) public view virtual override returns (NftInfo memory) {
        return _allInfo[nftId];
    }

    /**
     * @notice Get the length of random NFT list
     * @return uint256 length
     */
    function getRandNftCount() public view virtual override returns (uint256) {
        return _allRandID.length();
    }

    /**
     * @notice Get NFT ID index
     * @param index Index
     * @return uint256 nftId
     */
    function getRandNft(uint256 index) public view virtual override returns (uint256) {
        return _allRandID.at(index);
    }

    /**
     * @notice Get nft controller address
     * @return address nft controller address
     */
    function getNftController() public view virtual override returns (INftController) {
        return INftController(IPTokenFactory(factory).controller());
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "./interfaces/IPToken.sol";

abstract contract PTokenStorage is IPToken {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using AddressUpgradeable for address;

    // Constants used in calculation
    uint256 internal constant BASE_PERCENTS = 1e18;

    /// @notice keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    /// @notice ptoken factory contract address
    address public override factory;

    /// @notice Underlying NFT address
    address public override nftAddress;

    /// @notice nft fraction amount 1 NFT = pieceCount ptoken
    uint256 public override pieceCount;

    bytes32 public override DOMAIN_SEPARATOR;

    /// @notice Nonce for each EIP712 signature <user address, nonce>
    mapping(address => uint) public override nonces;

    // nft id list for random swap
    EnumerableSetUpgradeable.UintSet internal _allRandID;
    
    // All nft id info <NFT ID, NFT Info>
    mapping(uint256 => NftInfo) internal _allInfo;
}