// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

import "./interfaces/IControlledToken.sol";

/**
 * @title  PoolTogether V4 Controlled ERC20 Token
 * @author PoolTogether Inc Team
 * @notice  ERC20 Tokens with a controller for minting & burning
 */
contract ControlledToken is ERC20Permit, IControlledToken {
    /* ============ Global Variables ============ */

    /// @notice Interface to the contract responsible for controlling mint/burn
    address public override immutable controller;

    /// @notice ERC20 controlled token decimals.
    uint8 private immutable _decimals;

    /* ============ Events ============ */

    /// @dev Emitted when contract is deployed
    event Deployed(string name, string symbol, uint8 decimals, address indexed controller);

    /* ============ Modifiers ============ */

    /// @dev Function modifier to ensure that the caller is the controller contract
    modifier onlyController() {
        require(msg.sender == address(controller), "ControlledToken/only-controller");
        _;
    }

    /* ============ Constructor ============ */

    /// @notice Deploy the Controlled Token with Token Details and the Controller
    /// @param _name The name of the Token
    /// @param _symbol The symbol for the Token
    /// @param decimals_ The number of decimals for the Token
    /// @param _controller Address of the Controller contract for minting & burning
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 decimals_,
        address _controller
    ) ERC20Permit("PoolTogether ControlledToken") ERC20(_name, _symbol) {
        require(address(_controller) != address(0), "ControlledToken/controller-not-zero-address");
        controller = _controller;

        require(decimals_ > 0, "ControlledToken/decimals-gt-zero");
        _decimals = decimals_;

        emit Deployed(_name, _symbol, decimals_, _controller);
    }

    /* ============ External Functions ============ */

    /// @notice Allows the controller to mint tokens for a user account
    /// @dev May be overridden to provide more granular control over minting
    /// @param _user Address of the receiver of the minted tokens
    /// @param _amount Amount of tokens to mint
    function controllerMint(address _user, uint256 _amount)
        external
        virtual
        override
        onlyController
    {
        _mint(_user, _amount);
    }

    /// @notice Allows the controller to burn tokens from a user account
    /// @dev May be overridden to provide more granular control over burning
    /// @param _user Address of the holder account to burn tokens from
    /// @param _amount Amount of tokens to burn
    function controllerBurn(address _user, uint256 _amount)
        external
        virtual
        override
        onlyController
    {
        _burn(_user, _amount);
    }

    /// @notice Allows an operator via the controller to burn tokens on behalf of a user account
    /// @dev May be overridden to provide more granular control over operator-burning
    /// @param _operator Address of the operator performing the burn action via the controller contract
    /// @param _user Address of the holder account to burn tokens from
    /// @param _amount Amount of tokens to burn
    function controllerBurnFrom(
        address _operator,
        address _user,
        uint256 _amount
    ) external virtual override onlyController {
        if (_operator != _user) {
            _approve(_user, _operator, allowance(_user, _operator) - _amount);
        }

        _burn(_user, _amount);
    }

    /// @notice Returns the ERC20 controlled token decimals.
    /// @dev This value should be equal to the decimals of the token used to deposit into the pool.
    /// @return uint8 decimals.
    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/extensions/draft-ERC20Permit.sol)

pragma solidity ^0.8.0;

import "./draft-IERC20Permit.sol";
import "../ERC20.sol";
import "../../../utils/cryptography/draft-EIP712.sol";
import "../../../utils/cryptography/ECDSA.sol";
import "../../../utils/Counters.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    /**
     * @dev In previous versions `_PERMIT_TYPEHASH` was declared as `immutable`.
     * However, to ensure consistency with the upgradeable transpiler, we will continue
     * to reserve a slot.
     * @custom:oz-renamed-from _PERMIT_TYPEHASH
     */
    // solhint-disable-next-line var-name-mixedcase
    bytes32 private _PERMIT_TYPEHASH_DEPRECATED_SLOT;

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name) EIP712(name, "1") {}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/** @title IControlledToken
  * @author PoolTogether Inc Team
  * @notice ERC20 Tokens with a controller for minting & burning.
*/
interface IControlledToken is IERC20 {

    /** 
        @notice Interface to the contract responsible for controlling mint/burn
    */
    function controller() external view returns (address);

    /** 
      * @notice Allows the controller to mint tokens for a user account
      * @dev May be overridden to provide more granular control over minting
      * @param user Address of the receiver of the minted tokens
      * @param amount Amount of tokens to mint
    */
    function controllerMint(address user, uint256 amount) external;

    /** 
      * @notice Allows the controller to burn tokens from a user account
      * @dev May be overridden to provide more granular control over burning
      * @param user Address of the holder account to burn tokens from
      * @param amount Amount of tokens to burn
    */
    function controllerBurn(address user, uint256 amount) external;

    /** 
      * @notice Allows an operator via the controller to burn tokens on behalf of a user account
      * @dev May be overridden to provide more granular control over operator-burning
      * @param operator Address of the operator performing the burn action via the controller contract
      * @param user Address of the holder account to burn tokens from
      * @param amount Amount of tokens to burn
    */
    function controllerBurnFrom(
        address operator,
        address user,
        uint256 amount
    ) external;
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

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
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
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
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
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
        }
        _balances[to] += amount;

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
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

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
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./libraries/ExtendedSafeCastLib.sol";
import "./libraries/TwabLib.sol";
import "./interfaces/ITicket.sol";
import "./ControlledToken.sol";

/**
  * @title  PoolTogether V4 Ticket
  * @author PoolTogether Inc Team
  * @notice The Ticket extends the standard ERC20 and ControlledToken interfaces with time-weighted average balance functionality.
            The average balance held by a user between two timestamps can be calculated, as well as the historic balance.  The
            historic total supply is available as well as the average total supply between two timestamps.

            A user may "delegate" their balance; increasing another user's historic balance while retaining their tokens.
*/
contract Ticket is ControlledToken, ITicket {
    using SafeERC20 for IERC20;
    using ExtendedSafeCastLib for uint256;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private immutable _DELEGATE_TYPEHASH =
        keccak256("Delegate(address user,address delegate,uint256 nonce,uint256 deadline)");

    /// @notice Record of token holders TWABs for each account.
    mapping(address => TwabLib.Account) internal userTwabs;

    /// @notice Record of tickets total supply and ring buff parameters used for observation.
    TwabLib.Account internal totalSupplyTwab;

    /// @notice Mapping of delegates.  Each address can delegate their ticket power to another.
    mapping(address => address) internal delegates;

    /* ============ Constructor ============ */

    /**
     * @notice Constructs Ticket with passed parameters.
     * @param _name ERC20 ticket token name.
     * @param _symbol ERC20 ticket token symbol.
     * @param decimals_ ERC20 ticket token decimals.
     * @param _controller ERC20 ticket controller address (ie: Prize Pool address).
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 decimals_,
        address _controller
    ) ControlledToken(_name, _symbol, decimals_, _controller) {}

    /* ============ External Functions ============ */

    /// @inheritdoc ITicket
    function getAccountDetails(address _user)
        external
        view
        override
        returns (TwabLib.AccountDetails memory)
    {
        return userTwabs[_user].details;
    }

    /// @inheritdoc ITicket
    function getTwab(address _user, uint16 _index)
        external
        view
        override
        returns (ObservationLib.Observation memory)
    {
        return userTwabs[_user].twabs[_index];
    }

    /// @inheritdoc ITicket
    function getBalanceAt(address _user, uint64 _target) external view override returns (uint256) {
        TwabLib.Account storage account = userTwabs[_user];

        return
            TwabLib.getBalanceAt(
                account.twabs,
                account.details,
                uint32(_target),
                uint32(block.timestamp)
            );
    }

    /// @inheritdoc ITicket
    function getAverageBalancesBetween(
        address _user,
        uint64[] calldata _startTimes,
        uint64[] calldata _endTimes
    ) external view override returns (uint256[] memory) {
        return _getAverageBalancesBetween(userTwabs[_user], _startTimes, _endTimes);
    }

    /// @inheritdoc ITicket
    function getAverageTotalSuppliesBetween(
        uint64[] calldata _startTimes,
        uint64[] calldata _endTimes
    ) external view override returns (uint256[] memory) {
        return _getAverageBalancesBetween(totalSupplyTwab, _startTimes, _endTimes);
    }

    /// @inheritdoc ITicket
    function getAverageBalanceBetween(
        address _user,
        uint64 _startTime,
        uint64 _endTime
    ) external view override returns (uint256) {
        TwabLib.Account storage account = userTwabs[_user];

        return
            TwabLib.getAverageBalanceBetween(
                account.twabs,
                account.details,
                uint32(_startTime),
                uint32(_endTime),
                uint32(block.timestamp)
            );
    }

    /// @inheritdoc ITicket
    function getBalancesAt(address _user, uint64[] calldata _targets)
        external
        view
        override
        returns (uint256[] memory)
    {
        uint256 length = _targets.length;
        uint256[] memory _balances = new uint256[](length);

        TwabLib.Account storage twabContext = userTwabs[_user];
        TwabLib.AccountDetails memory details = twabContext.details;

        for (uint256 i = 0; i < length; i++) {
            _balances[i] = TwabLib.getBalanceAt(
                twabContext.twabs,
                details,
                uint32(_targets[i]),
                uint32(block.timestamp)
            );
        }

        return _balances;
    }

    /// @inheritdoc ITicket
    function getTotalSupplyAt(uint64 _target) external view override returns (uint256) {
        return
            TwabLib.getBalanceAt(
                totalSupplyTwab.twabs,
                totalSupplyTwab.details,
                uint32(_target),
                uint32(block.timestamp)
            );
    }

    /// @inheritdoc ITicket
    function getTotalSuppliesAt(uint64[] calldata _targets)
        external
        view
        override
        returns (uint256[] memory)
    {
        uint256 length = _targets.length;
        uint256[] memory totalSupplies = new uint256[](length);

        TwabLib.AccountDetails memory details = totalSupplyTwab.details;

        for (uint256 i = 0; i < length; i++) {
            totalSupplies[i] = TwabLib.getBalanceAt(
                totalSupplyTwab.twabs,
                details,
                uint32(_targets[i]),
                uint32(block.timestamp)
            );
        }

        return totalSupplies;
    }

    /// @inheritdoc ITicket
    function delegateOf(address _user) external view override returns (address) {
        return delegates[_user];
    }

    /// @inheritdoc ITicket
    function controllerDelegateFor(address _user, address _to) external override onlyController {
        _delegate(_user, _to);
    }

    /// @inheritdoc ITicket
    function delegateWithSignature(
        address _user,
        address _newDelegate,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external virtual override {
        require(block.timestamp <= _deadline, "Ticket/delegate-expired-deadline");

        bytes32 structHash = keccak256(abi.encode(_DELEGATE_TYPEHASH, _user, _newDelegate, _useNonce(_user), _deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, _v, _r, _s);
        require(signer == _user, "Ticket/delegate-invalid-signature");

        _delegate(_user, _newDelegate);
    }

    /// @inheritdoc ITicket
    function delegate(address _to) external virtual override {
        _delegate(msg.sender, _to);
    }

    /// @notice Delegates a users chance to another
    /// @param _user The user whose balance should be delegated
    /// @param _to The delegate
    function _delegate(address _user, address _to) internal {
        uint256 balance = balanceOf(_user);
        address currentDelegate = delegates[_user];

        if (currentDelegate == _to) {
            return;
        }

        delegates[_user] = _to;

        _transferTwab(currentDelegate, _to, balance);

        emit Delegated(_user, _to);
    }

    /* ============ Internal Functions ============ */

    /**
     * @notice Retrieves the average balances held by a user for a given time frame.
     * @param _account The user whose balance is checked.
     * @param _startTimes The start time of the time frame.
     * @param _endTimes The end time of the time frame.
     * @return The average balance that the user held during the time frame.
     */
    function _getAverageBalancesBetween(
        TwabLib.Account storage _account,
        uint64[] calldata _startTimes,
        uint64[] calldata _endTimes
    ) internal view returns (uint256[] memory) {
        uint256 startTimesLength = _startTimes.length;
        require(startTimesLength == _endTimes.length, "Ticket/start-end-times-length-match");

        TwabLib.AccountDetails memory accountDetails = _account.details;

        uint256[] memory averageBalances = new uint256[](startTimesLength);
        uint32 currentTimestamp = uint32(block.timestamp);

        for (uint256 i = 0; i < startTimesLength; i++) {
            averageBalances[i] = TwabLib.getAverageBalanceBetween(
                _account.twabs,
                accountDetails,
                uint32(_startTimes[i]),
                uint32(_endTimes[i]),
                currentTimestamp
            );
        }

        return averageBalances;
    }

    // @inheritdoc ERC20
    function _beforeTokenTransfer(address _from, address _to, uint256 _amount) internal override {
        if (_from == _to) {
            return;
        }

        address _fromDelegate;
        if (_from != address(0)) {
            _fromDelegate = delegates[_from];
        }

        address _toDelegate;
        if (_to != address(0)) {
            _toDelegate = delegates[_to];
        }

        _transferTwab(_fromDelegate, _toDelegate, _amount);
    }

    /// @notice Transfers the given TWAB balance from one user to another
    /// @param _from The user to transfer the balance from.  May be zero in the event of a mint.
    /// @param _to The user to transfer the balance to.  May be zero in the event of a burn.
    /// @param _amount The balance that is being transferred.
    function _transferTwab(address _from, address _to, uint256 _amount) internal {
        // If we are transferring tokens from a delegated account to an undelegated account
        if (_from != address(0)) {
            _decreaseUserTwab(_from, _amount);

            if (_to == address(0)) {
                _decreaseTotalSupplyTwab(_amount);
            }
        }

        // If we are transferring tokens from an undelegated account to a delegated account
        if (_to != address(0)) {
            _increaseUserTwab(_to, _amount);

            if (_from == address(0)) {
                _increaseTotalSupplyTwab(_amount);
            }
        }
    }

    /**
     * @notice Increase `_to` TWAB balance.
     * @param _to Address of the delegate.
     * @param _amount Amount of tokens to be added to `_to` TWAB balance.
     */
    function _increaseUserTwab(
        address _to,
        uint256 _amount
    ) internal {
        if (_amount == 0) {
            return;
        }

        TwabLib.Account storage _account = userTwabs[_to];

        (
            TwabLib.AccountDetails memory accountDetails,
            ObservationLib.Observation memory twab,
            bool isNew
        ) = TwabLib.increaseBalance(_account, _amount.toUint208(), uint32(block.timestamp));

        _account.details = accountDetails;

        if (isNew) {
            emit NewUserTwab(_to, twab);
        }
    }

    /**
     * @notice Decrease `_to` TWAB balance.
     * @param _to Address of the delegate.
     * @param _amount Amount of tokens to be added to `_to` TWAB balance.
     */
    function _decreaseUserTwab(
        address _to,
        uint256 _amount
    ) internal {
        if (_amount == 0) {
            return;
        }

        TwabLib.Account storage _account = userTwabs[_to];

        (
            TwabLib.AccountDetails memory accountDetails,
            ObservationLib.Observation memory twab,
            bool isNew
        ) = TwabLib.decreaseBalance(
                _account,
                _amount.toUint208(),
                "Ticket/twab-burn-lt-balance",
                uint32(block.timestamp)
            );

        _account.details = accountDetails;

        if (isNew) {
            emit NewUserTwab(_to, twab);
        }
    }

    /// @notice Decreases the total supply twab.  Should be called anytime a balance moves from delegated to undelegated
    /// @param _amount The amount to decrease the total by
    function _decreaseTotalSupplyTwab(uint256 _amount) internal {
        if (_amount == 0) {
            return;
        }

        (
            TwabLib.AccountDetails memory accountDetails,
            ObservationLib.Observation memory tsTwab,
            bool tsIsNew
        ) = TwabLib.decreaseBalance(
                totalSupplyTwab,
                _amount.toUint208(),
                "Ticket/burn-amount-exceeds-total-supply-twab",
                uint32(block.timestamp)
            );

        totalSupplyTwab.details = accountDetails;

        if (tsIsNew) {
            emit NewTotalSupplyTwab(tsTwab);
        }
    }

    /// @notice Increases the total supply twab.  Should be called anytime a balance moves from undelegated to delegated
    /// @param _amount The amount to increase the total by
    function _increaseTotalSupplyTwab(uint256 _amount) internal {
        if (_amount == 0) {
            return;
        }

        (
            TwabLib.AccountDetails memory accountDetails,
            ObservationLib.Observation memory _totalSupply,
            bool tsIsNew
        ) = TwabLib.increaseBalance(totalSupplyTwab, _amount.toUint208(), uint32(block.timestamp));

        totalSupplyTwab.details = accountDetails;

        if (tsIsNew) {
            emit NewTotalSupplyTwab(_totalSupply);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

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
library ExtendedSafeCastLib {

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     */
    function toUint104(uint256 _value) internal pure returns (uint104) {
        require(_value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(_value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     */
    function toUint208(uint256 _value) internal pure returns (uint208) {
        require(_value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(_value);
    }

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
    function toUint224(uint256 _value) internal pure returns (uint224) {
        require(_value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(_value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "./ExtendedSafeCastLib.sol";
import "./OverflowSafeComparatorLib.sol";
import "./RingBufferLib.sol";
import "./ObservationLib.sol";

/**
  * @title  PoolTogether V4 TwabLib (Library)
  * @author PoolTogether Inc Team
  * @dev    Time-Weighted Average Balance Library for ERC20 tokens.
  * @notice This TwabLib adds on-chain historical lookups to a user(s) time-weighted average balance.
            Each user is mapped to an Account struct containing the TWAB history (ring buffer) and
            ring buffer parameters. Every token.transfer() creates a new TWAB checkpoint. The new TWAB
            checkpoint is stored in the circular ring buffer, as either a new checkpoint or rewriting
            a previous checkpoint with new parameters. The TwabLib (using existing blocktimes of 1block/15sec)
            guarantees minimum 7.4 years of search history.
 */
library TwabLib {
    using OverflowSafeComparatorLib for uint32;
    using ExtendedSafeCastLib for uint256;

    /**
      * @notice Sets max ring buffer length in the Account.twabs Observation list.
                As users transfer/mint/burn tickets new Observation checkpoints are
                recorded. The current max cardinality guarantees a seven year minimum,
                of accurate historical lookups with current estimates of 1 new block
                every 15 seconds - assuming each block contains a transfer to trigger an
                observation write to storage.
      * @dev    The user Account.AccountDetails.cardinality parameter can NOT exceed
                the max cardinality variable. Preventing "corrupted" ring buffer lookup
                pointers and new observation checkpoints.

                The MAX_CARDINALITY in fact guarantees at least 7.4 years of records:
                If 14 = block time in seconds
                (2**24) * 14 = 234881024 seconds of history
                234881024 / (365 * 24 * 60 * 60) ~= 7.44 years
    */
    uint24 public constant MAX_CARDINALITY = 16777215; // 2**24

    /** @notice Struct ring buffer parameters for single user Account
      * @param balance       Current balance for an Account
      * @param nextTwabIndex Next uninitialized or updatable ring buffer checkpoint storage slot
      * @param cardinality   Current total "initialized" ring buffer checkpoints for single user AccountDetails.
                             Used to set initial boundary conditions for an efficient binary search.
    */
    struct AccountDetails {
        uint208 balance;
        uint24 nextTwabIndex;
        uint24 cardinality;
    }

    /// @notice Combines account details with their twab history
    /// @param details The account details
    /// @param twabs The history of twabs for this account
    struct Account {
        AccountDetails details;
        ObservationLib.Observation[MAX_CARDINALITY] twabs;
    }

    /// @notice Increases an account's balance and records a new twab.
    /// @param _account The account whose balance will be increased
    /// @param _amount The amount to increase the balance by
    /// @param _currentTime The current time
    /// @return accountDetails The new AccountDetails
    /// @return twab The user's latest TWAB
    /// @return isNew Whether the TWAB is new
    function increaseBalance(
        Account storage _account,
        uint208 _amount,
        uint32 _currentTime
    )
        internal
        returns (
            AccountDetails memory accountDetails,
            ObservationLib.Observation memory twab,
            bool isNew
        )
    {
        AccountDetails memory _accountDetails = _account.details;
        (accountDetails, twab, isNew) = _nextTwab(_account.twabs, _accountDetails, _currentTime);
        accountDetails.balance = _accountDetails.balance + _amount;
    }

    /** @notice Calculates the next TWAB checkpoint for an account with a decreasing balance.
     * @dev    With Account struct and amount decreasing calculates the next TWAB observable checkpoint.
     * @param _account        Account whose balance will be decreased
     * @param _amount         Amount to decrease the balance by
     * @param _revertMessage  Revert message for insufficient balance
     * @return accountDetails Updated Account.details struct
     * @return twab           TWAB observation (with decreasing average)
     * @return isNew          Whether TWAB is new or calling twice in the same block
     */
    function decreaseBalance(
        Account storage _account,
        uint208 _amount,
        string memory _revertMessage,
        uint32 _currentTime
    )
        internal
        returns (
            AccountDetails memory accountDetails,
            ObservationLib.Observation memory twab,
            bool isNew
        )
    {
        AccountDetails memory _accountDetails = _account.details;

        require(_accountDetails.balance >= _amount, _revertMessage);

        (accountDetails, twab, isNew) = _nextTwab(_account.twabs, _accountDetails, _currentTime);
        unchecked {
            accountDetails.balance -= _amount;
        }
    }

    /** @notice Calculates the average balance held by a user for a given time frame.
      * @dev    Finds the average balance between start and end timestamp epochs.
                Validates the supplied end time is within the range of elapsed time i.e. less then timestamp of now.
      * @param _twabs          Individual user Observation recorded checkpoints passed as storage pointer
      * @param _accountDetails User AccountDetails struct loaded in memory
      * @param _startTime      Start of timestamp range as an epoch
      * @param _endTime        End of timestamp range as an epoch
      * @param _currentTime    Block.timestamp
      * @return Average balance of user held between epoch timestamps start and end
    */
    function getAverageBalanceBetween(
        ObservationLib.Observation[MAX_CARDINALITY] storage _twabs,
        AccountDetails memory _accountDetails,
        uint32 _startTime,
        uint32 _endTime,
        uint32 _currentTime
    ) internal view returns (uint256) {
        uint32 endTime = _endTime > _currentTime ? _currentTime : _endTime;

        return
            _getAverageBalanceBetween(_twabs, _accountDetails, _startTime, endTime, _currentTime);
    }

    /// @notice Retrieves the oldest TWAB
    /// @param _twabs The storage array of twabs
    /// @param _accountDetails The TWAB account details
    /// @return index The index of the oldest TWAB in the twabs array
    /// @return twab The oldest TWAB
    function oldestTwab(
        ObservationLib.Observation[MAX_CARDINALITY] storage _twabs,
        AccountDetails memory _accountDetails
    ) internal view returns (uint24 index, ObservationLib.Observation memory twab) {
        index = _accountDetails.nextTwabIndex;
        twab = _twabs[index];

        // If the TWAB is not initialized we go to the beginning of the TWAB circular buffer at index 0
        if (twab.timestamp == 0) {
            index = 0;
            twab = _twabs[0];
        }
    }

    /// @notice Retrieves the newest TWAB
    /// @param _twabs The storage array of twabs
    /// @param _accountDetails The TWAB account details
    /// @return index The index of the newest TWAB in the twabs array
    /// @return twab The newest TWAB
    function newestTwab(
        ObservationLib.Observation[MAX_CARDINALITY] storage _twabs,
        AccountDetails memory _accountDetails
    ) internal view returns (uint24 index, ObservationLib.Observation memory twab) {
        index = uint24(RingBufferLib.newestIndex(_accountDetails.nextTwabIndex, MAX_CARDINALITY));
        twab = _twabs[index];
    }

    /// @notice Retrieves amount at `_targetTime` timestamp
    /// @param _twabs List of TWABs to search through.
    /// @param _accountDetails Accounts details
    /// @param _targetTime Timestamp at which the reserved TWAB should be for.
    /// @return uint256 TWAB amount at `_targetTime`.
    function getBalanceAt(
        ObservationLib.Observation[MAX_CARDINALITY] storage _twabs,
        AccountDetails memory _accountDetails,
        uint32 _targetTime,
        uint32 _currentTime
    ) internal view returns (uint256) {
        uint32 timeToTarget = _targetTime > _currentTime ? _currentTime : _targetTime;
        return _getBalanceAt(_twabs, _accountDetails, timeToTarget, _currentTime);
    }

    /// @notice Calculates the average balance held by a user for a given time frame.
    /// @param _startTime The start time of the time frame.
    /// @param _endTime The end time of the time frame.
    /// @return The average balance that the user held during the time frame.
    function _getAverageBalanceBetween(
        ObservationLib.Observation[MAX_CARDINALITY] storage _twabs,
        AccountDetails memory _accountDetails,
        uint32 _startTime,
        uint32 _endTime,
        uint32 _currentTime
    ) private view returns (uint256) {
        (uint24 oldestTwabIndex, ObservationLib.Observation memory oldTwab) = oldestTwab(
            _twabs,
            _accountDetails
        );

        (uint24 newestTwabIndex, ObservationLib.Observation memory newTwab) = newestTwab(
            _twabs,
            _accountDetails
        );

        ObservationLib.Observation memory startTwab = _calculateTwab(
            _twabs,
            _accountDetails,
            newTwab,
            oldTwab,
            newestTwabIndex,
            oldestTwabIndex,
            _startTime,
            _currentTime
        );

        ObservationLib.Observation memory endTwab = _calculateTwab(
            _twabs,
            _accountDetails,
            newTwab,
            oldTwab,
            newestTwabIndex,
            oldestTwabIndex,
            _endTime,
            _currentTime
        );

        // Difference in amount / time
        return (endTwab.amount - startTwab.amount) / OverflowSafeComparatorLib.checkedSub(endTwab.timestamp, startTwab.timestamp, _currentTime);
    }

    /** @notice Searches TWAB history and calculate the difference between amount(s)/timestamp(s) to return average balance
                between the Observations closes to the supplied targetTime.
      * @param _twabs          Individual user Observation recorded checkpoints passed as storage pointer
      * @param _accountDetails User AccountDetails struct loaded in memory
      * @param _targetTime     Target timestamp to filter Observations in the ring buffer binary search
      * @param _currentTime    Block.timestamp
      * @return uint256 Time-weighted average amount between two closest observations.
    */
    function _getBalanceAt(
        ObservationLib.Observation[MAX_CARDINALITY] storage _twabs,
        AccountDetails memory _accountDetails,
        uint32 _targetTime,
        uint32 _currentTime
    ) private view returns (uint256) {
        uint24 newestTwabIndex;
        ObservationLib.Observation memory afterOrAt;
        ObservationLib.Observation memory beforeOrAt;
        (newestTwabIndex, beforeOrAt) = newestTwab(_twabs, _accountDetails);

        // If `_targetTime` is chronologically after the newest TWAB, we can simply return the current balance
        if (beforeOrAt.timestamp.lte(_targetTime, _currentTime)) {
            return _accountDetails.balance;
        }

        uint24 oldestTwabIndex;
        // Now, set before to the oldest TWAB
        (oldestTwabIndex, beforeOrAt) = oldestTwab(_twabs, _accountDetails);

        // If `_targetTime` is chronologically before the oldest TWAB, we can early return
        if (_targetTime.lt(beforeOrAt.timestamp, _currentTime)) {
            return 0;
        }

        // Otherwise, we perform the `binarySearch`
        (beforeOrAt, afterOrAt) = ObservationLib.binarySearch(
            _twabs,
            newestTwabIndex,
            oldestTwabIndex,
            _targetTime,
            _accountDetails.cardinality,
            _currentTime
        );

        // Sum the difference in amounts and divide by the difference in timestamps.
        // The time-weighted average balance uses time measured between two epoch timestamps as
        // a constaint on the measurement when calculating the time weighted average balance.
        return
            (afterOrAt.amount - beforeOrAt.amount) / OverflowSafeComparatorLib.checkedSub(afterOrAt.timestamp, beforeOrAt.timestamp, _currentTime);
    }

    /** @notice Calculates a user TWAB for a target timestamp using the historical TWAB records.
                The balance is linearly interpolated: amount differences / timestamp differences
                using the simple (after.amount - before.amount / end.timestamp - start.timestamp) formula.
    /** @dev    Binary search in _calculateTwab fails when searching out of bounds. Thus, before
                searching we exclude target timestamps out of range of newest/oldest TWAB(s).
                IF a search is before or after the range we "extrapolate" a Observation from the expected state.
      * @param _twabs           Individual user Observation recorded checkpoints passed as storage pointer
      * @param _accountDetails  User AccountDetails struct loaded in memory
      * @param _newestTwab      Newest TWAB in history (end of ring buffer)
      * @param _oldestTwab      Olderst TWAB in history (end of ring buffer)
      * @param _newestTwabIndex Pointer in ring buffer to newest TWAB
      * @param _oldestTwabIndex Pointer in ring buffer to oldest TWAB
      * @param _targetTimestamp Epoch timestamp to calculate for time (T) in the TWAB
      * @param _time            Block.timestamp
      * @return accountDetails Updated Account.details struct
    */
    function _calculateTwab(
        ObservationLib.Observation[MAX_CARDINALITY] storage _twabs,
        AccountDetails memory _accountDetails,
        ObservationLib.Observation memory _newestTwab,
        ObservationLib.Observation memory _oldestTwab,
        uint24 _newestTwabIndex,
        uint24 _oldestTwabIndex,
        uint32 _targetTimestamp,
        uint32 _time
    ) private view returns (ObservationLib.Observation memory) {
        // If `_targetTimestamp` is chronologically after the newest TWAB, we extrapolate a new one
        if (_newestTwab.timestamp.lt(_targetTimestamp, _time)) {
            return _computeNextTwab(_newestTwab, _accountDetails.balance, _targetTimestamp);
        }

        if (_newestTwab.timestamp == _targetTimestamp) {
            return _newestTwab;
        }

        if (_oldestTwab.timestamp == _targetTimestamp) {
            return _oldestTwab;
        }

        // If `_targetTimestamp` is chronologically before the oldest TWAB, we create a zero twab
        if (_targetTimestamp.lt(_oldestTwab.timestamp, _time)) {
            return ObservationLib.Observation({ amount: 0, timestamp: _targetTimestamp });
        }

        // Otherwise, both timestamps must be surrounded by twabs.
        (
            ObservationLib.Observation memory beforeOrAtStart,
            ObservationLib.Observation memory afterOrAtStart
        ) = ObservationLib.binarySearch(
                _twabs,
                _newestTwabIndex,
                _oldestTwabIndex,
                _targetTimestamp,
                _accountDetails.cardinality,
                _time
            );

        uint224 heldBalance = (afterOrAtStart.amount - beforeOrAtStart.amount) /
            OverflowSafeComparatorLib.checkedSub(afterOrAtStart.timestamp, beforeOrAtStart.timestamp, _time);

        return _computeNextTwab(beforeOrAtStart, heldBalance, _targetTimestamp);
    }

    /**
     * @notice Calculates the next TWAB using the newestTwab and updated balance.
     * @dev    Storage of the TWAB obersation is managed by the calling function and not _computeNextTwab.
     * @param _currentTwab    Newest Observation in the Account.twabs list
     * @param _currentBalance User balance at time of most recent (newest) checkpoint write
     * @param _time           Current block.timestamp
     * @return TWAB Observation
     */
    function _computeNextTwab(
        ObservationLib.Observation memory _currentTwab,
        uint224 _currentBalance,
        uint32 _time
    ) private pure returns (ObservationLib.Observation memory) {
        // New twab amount = last twab amount (or zero) + (current amount * elapsed seconds)
        return
            ObservationLib.Observation({
                amount: _currentTwab.amount +
                    _currentBalance *
                    (_time.checkedSub(_currentTwab.timestamp, _time)),
                timestamp: _time
            });
    }

    /// @notice Sets a new TWAB Observation at the next available index and returns the new account details.
    /// @dev Note that if _currentTime is before the last observation timestamp, it appears as an overflow
    /// @param _twabs The twabs array to insert into
    /// @param _accountDetails The current account details
    /// @param _currentTime The current time
    /// @return accountDetails The new account details
    /// @return twab The newest twab (may or may not be brand-new)
    /// @return isNew Whether the newest twab was created by this call
    function _nextTwab(
        ObservationLib.Observation[MAX_CARDINALITY] storage _twabs,
        AccountDetails memory _accountDetails,
        uint32 _currentTime
    )
        private
        returns (
            AccountDetails memory accountDetails,
            ObservationLib.Observation memory twab,
            bool isNew
        )
    {
        (, ObservationLib.Observation memory _newestTwab) = newestTwab(_twabs, _accountDetails);

        // if we're in the same block, return
        if (_newestTwab.timestamp == _currentTime) {
            return (_accountDetails, _newestTwab, false);
        }

        ObservationLib.Observation memory newTwab = _computeNextTwab(
            _newestTwab,
            _accountDetails.balance,
            _currentTime
        );

        _twabs[_accountDetails.nextTwabIndex] = newTwab;

        AccountDetails memory nextAccountDetails = push(_accountDetails);

        return (nextAccountDetails, newTwab, true);
    }

    /// @notice "Pushes" a new element on the AccountDetails ring buffer, and returns the new AccountDetails
    /// @param _accountDetails The account details from which to pull the cardinality and next index
    /// @return The new AccountDetails
    function push(AccountDetails memory _accountDetails)
        internal
        pure
        returns (AccountDetails memory)
    {
        _accountDetails.nextTwabIndex = uint24(
            RingBufferLib.nextIndex(_accountDetails.nextTwabIndex, MAX_CARDINALITY)
        );

        // Prevent the Account specific cardinality from exceeding the MAX_CARDINALITY.
        // The ring buffer length is limited by MAX_CARDINALITY. IF the account.cardinality
        // exceeds the max cardinality, new observations would be incorrectly set or the
        // observation would be out of "bounds" of the ring buffer. Once reached the
        // AccountDetails.cardinality will continue to be equal to max cardinality.
        if (_accountDetails.cardinality < MAX_CARDINALITY) {
            _accountDetails.cardinality += 1;
        }

        return _accountDetails;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "../libraries/TwabLib.sol";
import "./IControlledToken.sol";

interface ITicket is IControlledToken {
    /**
     * @notice A struct containing details for an Account.
     * @param balance The current balance for an Account.
     * @param nextTwabIndex The next available index to store a new twab.
     * @param cardinality The number of recorded twabs (plus one!).
     */
    struct AccountDetails {
        uint224 balance;
        uint16 nextTwabIndex;
        uint16 cardinality;
    }

    /**
     * @notice Combines account details with their twab history.
     * @param details The account details.
     * @param twabs The history of twabs for this account.
     */
    struct Account {
        AccountDetails details;
        ObservationLib.Observation[65535] twabs;
    }

    /**
     * @notice Emitted when TWAB balance has been delegated to another user.
     * @param delegator Address of the delegator.
     * @param delegate Address of the delegate.
     */
    event Delegated(address indexed delegator, address indexed delegate);

    /**
     * @notice Emitted when ticket is initialized.
     * @param name Ticket name (eg: PoolTogether Dai Ticket (Compound)).
     * @param symbol Ticket symbol (eg: PcDAI).
     * @param decimals Ticket decimals.
     * @param controller Token controller address.
     */
    event TicketInitialized(string name, string symbol, uint8 decimals, address indexed controller);

    /**
     * @notice Emitted when a new TWAB has been recorded.
     * @param delegate The recipient of the ticket power (may be the same as the user).
     * @param newTwab Updated TWAB of a ticket holder after a successful TWAB recording.
     */
    event NewUserTwab(
        address indexed delegate,
        ObservationLib.Observation newTwab
    );

    /**
     * @notice Emitted when a new total supply TWAB has been recorded.
     * @param newTotalSupplyTwab Updated TWAB of tickets total supply after a successful total supply TWAB recording.
     */
    event NewTotalSupplyTwab(ObservationLib.Observation newTotalSupplyTwab);

    /**
     * @notice Retrieves the address of the delegate to whom `user` has delegated their tickets.
     * @dev Address of the delegate will be the zero address if `user` has not delegated their tickets.
     * @param user Address of the delegator.
     * @return Address of the delegate.
     */
    function delegateOf(address user) external view returns (address);

    /**
    * @notice Delegate time-weighted average balances to an alternative address.
    * @dev    Transfers (including mints) trigger the storage of a TWAB in delegate(s) account, instead of the
              targetted sender and/or recipient address(s).
    * @dev    To reset the delegate, pass the zero address (0x000.000) as `to` parameter.
    * @dev Current delegate address should be different from the new delegate address `to`.
    * @param  to Recipient of delegated TWAB.
    */
    function delegate(address to) external;

    /**
     * @notice Allows the controller to delegate on a users behalf.
     * @param user The user for whom to delegate
     * @param delegate The new delegate
     */
    function controllerDelegateFor(address user, address delegate) external;

    /**
     * @notice Allows a user to delegate via signature
     * @param user The user who is delegating
     * @param delegate The new delegate
     * @param deadline The timestamp by which this must be submitted
     * @param v The v portion of the ECDSA sig
     * @param r The r portion of the ECDSA sig
     * @param s The s portion of the ECDSA sig
     */
    function delegateWithSignature(
        address user,
        address delegate,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @notice Gets a users twab context.  This is a struct with their balance, next twab index, and cardinality.
     * @param user The user for whom to fetch the TWAB context.
     * @return The TWAB context, which includes { balance, nextTwabIndex, cardinality }
     */
    function getAccountDetails(address user) external view returns (TwabLib.AccountDetails memory);

    /**
     * @notice Gets the TWAB at a specific index for a user.
     * @param user The user for whom to fetch the TWAB.
     * @param index The index of the TWAB to fetch.
     * @return The TWAB, which includes the twab amount and the timestamp.
     */
    function getTwab(address user, uint16 index)
        external
        view
        returns (ObservationLib.Observation memory);

    /**
     * @notice Retrieves `user` TWAB balance.
     * @param user Address of the user whose TWAB is being fetched.
     * @param timestamp Timestamp at which we want to retrieve the TWAB balance.
     * @return The TWAB balance at the given timestamp.
     */
    function getBalanceAt(address user, uint64 timestamp) external view returns (uint256);

    /**
     * @notice Retrieves `user` TWAB balances.
     * @param user Address of the user whose TWABs are being fetched.
     * @param timestamps Timestamps range at which we want to retrieve the TWAB balances.
     * @return `user` TWAB balances.
     */
    function getBalancesAt(address user, uint64[] calldata timestamps)
        external
        view
        returns (uint256[] memory);

    /**
     * @notice Retrieves the average balance held by a user for a given time frame.
     * @param user The user whose balance is checked.
     * @param startTime The start time of the time frame.
     * @param endTime The end time of the time frame.
     * @return The average balance that the user held during the time frame.
     */
    function getAverageBalanceBetween(
        address user,
        uint64 startTime,
        uint64 endTime
    ) external view returns (uint256);

    /**
     * @notice Retrieves the average balances held by a user for a given time frame.
     * @param user The user whose balance is checked.
     * @param startTimes The start time of the time frame.
     * @param endTimes The end time of the time frame.
     * @return The average balance that the user held during the time frame.
     */
    function getAverageBalancesBetween(
        address user,
        uint64[] calldata startTimes,
        uint64[] calldata endTimes
    ) external view returns (uint256[] memory);

    /**
     * @notice Retrieves the total supply TWAB balance at the given timestamp.
     * @param timestamp Timestamp at which we want to retrieve the total supply TWAB balance.
     * @return The total supply TWAB balance at the given timestamp.
     */
    function getTotalSupplyAt(uint64 timestamp) external view returns (uint256);

    /**
     * @notice Retrieves the total supply TWAB balance between the given timestamps range.
     * @param timestamps Timestamps range at which we want to retrieve the total supply TWAB balance.
     * @return Total supply TWAB balances.
     */
    function getTotalSuppliesAt(uint64[] calldata timestamps)
        external
        view
        returns (uint256[] memory);

    /**
     * @notice Retrieves the average total supply balance for a set of given time frames.
     * @param startTimes Array of start times.
     * @param endTimes Array of end times.
     * @return The average total supplies held during the time frame.
     */
    function getAverageTotalSuppliesBetween(
        uint64[] calldata startTimes,
        uint64[] calldata endTimes
    ) external view returns (uint256[] memory);
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

/// @title OverflowSafeComparatorLib library to share comparator functions between contracts
/// @dev Code taken from Uniswap V3 Oracle.sol: https://github.com/Uniswap/v3-core/blob/3e88af408132fc957e3e406f65a0ce2b1ca06c3d/contracts/libraries/Oracle.sol
/// @author PoolTogether Inc.
library OverflowSafeComparatorLib {
    /// @notice 32-bit timestamps comparator.
    /// @dev safe for 0 or 1 overflows, `_a` and `_b` must be chronologically before or equal to time.
    /// @param _a A comparison timestamp from which to determine the relative position of `_timestamp`.
    /// @param _b Timestamp to compare against `_a`.
    /// @param _timestamp A timestamp truncated to 32 bits.
    /// @return bool Whether `_a` is chronologically < `_b`.
    function lt(
        uint32 _a,
        uint32 _b,
        uint32 _timestamp
    ) internal pure returns (bool) {
        // No need to adjust if there hasn't been an overflow
        if (_a <= _timestamp && _b <= _timestamp) return _a < _b;

        uint256 aAdjusted = _a > _timestamp ? _a : _a + 2**32;
        uint256 bAdjusted = _b > _timestamp ? _b : _b + 2**32;

        return aAdjusted < bAdjusted;
    }

    /// @notice 32-bit timestamps comparator.
    /// @dev safe for 0 or 1 overflows, `_a` and `_b` must be chronologically before or equal to time.
    /// @param _a A comparison timestamp from which to determine the relative position of `_timestamp`.
    /// @param _b Timestamp to compare against `_a`.
    /// @param _timestamp A timestamp truncated to 32 bits.
    /// @return bool Whether `_a` is chronologically <= `_b`.
    function lte(
        uint32 _a,
        uint32 _b,
        uint32 _timestamp
    ) internal pure returns (bool) {

        // No need to adjust if there hasn't been an overflow
        if (_a <= _timestamp && _b <= _timestamp) return _a <= _b;

        uint256 aAdjusted = _a > _timestamp ? _a : _a + 2**32;
        uint256 bAdjusted = _b > _timestamp ? _b : _b + 2**32;

        return aAdjusted <= bAdjusted;
    }

    /// @notice 32-bit timestamp subtractor
    /// @dev safe for 0 or 1 overflows, where `_a` and `_b` must be chronologically before or equal to time
    /// @param _a The subtraction left operand
    /// @param _b The subtraction right operand
    /// @param _timestamp The current time.  Expected to be chronologically after both.
    /// @return The difference between a and b, adjusted for overflow
    function checkedSub(
        uint32 _a,
        uint32 _b,
        uint32 _timestamp
    ) internal pure returns (uint32) {
        // No need to adjust if there hasn't been an overflow

        if (_a <= _timestamp && _b <= _timestamp) return _a - _b;

        uint256 aAdjusted = _a > _timestamp ? _a : _a + 2**32;
        uint256 bAdjusted = _b > _timestamp ? _b : _b + 2**32;

        return uint32(aAdjusted - bAdjusted);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

library RingBufferLib {
    /**
    * @notice Returns wrapped TWAB index.
    * @dev  In order to navigate the TWAB circular buffer, we need to use the modulo operator.
    * @dev  For example, if `_index` is equal to 32 and the TWAB circular buffer is of `_cardinality` 32,
    *       it will return 0 and will point to the first element of the array.
    * @param _index Index used to navigate through the TWAB circular buffer.
    * @param _cardinality TWAB buffer cardinality.
    * @return TWAB index.
    */
    function wrap(uint256 _index, uint256 _cardinality) internal pure returns (uint256) {
        return _index % _cardinality;
    }

    /**
    * @notice Computes the negative offset from the given index, wrapped by the cardinality.
    * @dev  We add `_cardinality` to `_index` to be able to offset even if `_amount` is superior to `_cardinality`.
    * @param _index The index from which to offset
    * @param _amount The number of indices to offset.  This is subtracted from the given index.
    * @param _cardinality The number of elements in the ring buffer
    * @return Offsetted index.
     */
    function offset(
        uint256 _index,
        uint256 _amount,
        uint256 _cardinality
    ) internal pure returns (uint256) {
        return wrap(_index + _cardinality - _amount, _cardinality);
    }

    /// @notice Returns the index of the last recorded TWAB
    /// @param _nextIndex The next available twab index.  This will be recorded to next.
    /// @param _cardinality The cardinality of the TWAB history.
    /// @return The index of the last recorded TWAB
    function newestIndex(uint256 _nextIndex, uint256 _cardinality)
        internal
        pure
        returns (uint256)
    {
        if (_cardinality == 0) {
            return 0;
        }

        return wrap(_nextIndex + _cardinality - 1, _cardinality);
    }

    /// @notice Computes the ring buffer index that follows the given one, wrapped by cardinality
    /// @param _index The index to increment
    /// @param _cardinality The number of elements in the Ring Buffer
    /// @return The next index relative to the given index.  Will wrap around to 0 if the next index == cardinality
    function nextIndex(uint256 _index, uint256 _cardinality)
        internal
        pure
        returns (uint256)
    {
        return wrap(_index + 1, _cardinality);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";

import "./OverflowSafeComparatorLib.sol";
import "./RingBufferLib.sol";

/**
* @title Observation Library
* @notice This library allows one to store an array of timestamped values and efficiently binary search them.
* @dev Largely pulled from Uniswap V3 Oracle.sol: https://github.com/Uniswap/v3-core/blob/c05a0e2c8c08c460fb4d05cfdda30b3ad8deeaac/contracts/libraries/Oracle.sol
* @author PoolTogether Inc.
*/
library ObservationLib {
    using OverflowSafeComparatorLib for uint32;
    using SafeCast for uint256;

    /// @notice The maximum number of observations
    uint24 public constant MAX_CARDINALITY = 16777215; // 2**24

    /**
    * @notice Observation, which includes an amount and timestamp.
    * @param amount `amount` at `timestamp`.
    * @param timestamp Recorded `timestamp`.
    */
    struct Observation {
        uint224 amount;
        uint32 timestamp;
    }

    /**
    * @notice Fetches Observations `beforeOrAt` and `atOrAfter` a `_target`, eg: where [`beforeOrAt`, `atOrAfter`] is satisfied.
    * The result may be the same Observation, or adjacent Observations.
    * @dev The answer must be contained in the array used when the target is located within the stored Observation.
    * boundaries: older than the most recent Observation and younger, or the same age as, the oldest Observation.
    * @dev  If `_newestObservationIndex` is less than `_oldestObservationIndex`, it means that we've wrapped around the circular buffer.
    *       So the most recent observation will be at `_oldestObservationIndex + _cardinality - 1`, at the beginning of the circular buffer.
    * @param _observations List of Observations to search through.
    * @param _newestObservationIndex Index of the newest Observation. Right side of the circular buffer.
    * @param _oldestObservationIndex Index of the oldest Observation. Left side of the circular buffer.
    * @param _target Timestamp at which we are searching the Observation.
    * @param _cardinality Cardinality of the circular buffer we are searching through.
    * @param _time Timestamp at which we perform the binary search.
    * @return beforeOrAt Observation recorded before, or at, the target.
    * @return atOrAfter Observation recorded at, or after, the target.
    */
    function binarySearch(
        Observation[MAX_CARDINALITY] storage _observations,
        uint24 _newestObservationIndex,
        uint24 _oldestObservationIndex,
        uint32 _target,
        uint24 _cardinality,
        uint32 _time
    ) internal view returns (Observation memory beforeOrAt, Observation memory atOrAfter) {
        uint256 leftSide = _oldestObservationIndex;
        uint256 rightSide = _newestObservationIndex < leftSide
            ? leftSide + _cardinality - 1
            : _newestObservationIndex;
        uint256 currentIndex;

        while (true) {
            // We start our search in the middle of the `leftSide` and `rightSide`.
            // After each iteration, we narrow down the search to the left or the right side while still starting our search in the middle.
            currentIndex = (leftSide + rightSide) / 2;

            beforeOrAt = _observations[uint24(RingBufferLib.wrap(currentIndex, _cardinality))];
            uint32 beforeOrAtTimestamp = beforeOrAt.timestamp;

            // We've landed on an uninitialized timestamp, keep searching higher (more recently).
            if (beforeOrAtTimestamp == 0) {
                leftSide = currentIndex + 1;
                continue;
            }

            atOrAfter = _observations[uint24(RingBufferLib.nextIndex(currentIndex, _cardinality))];

            bool targetAtOrAfter = beforeOrAtTimestamp.lte(_target, _time);

            // Check if we've found the corresponding Observation.
            if (targetAtOrAfter && _target.lte(atOrAfter.timestamp, _time)) {
                break;
            }

            // If `beforeOrAtTimestamp` is greater than `_target`, then we keep searching lower. To the left of the current index.
            if (!targetAtOrAfter) {
                rightSide = currentIndex - 1;
            } else {
                // Otherwise, we keep searching higher. To the left of the current index.
                leftSide = currentIndex + 1;
            }
        }
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@pooltogether/owner-manager-contracts/contracts/Ownable.sol";

import "../external/compound/ICompLike.sol";
import "../interfaces/IPrizePool.sol";
import "../interfaces/ITicket.sol";

/**
  * @title  PoolTogether V4 PrizePool
  * @author PoolTogether Inc Team
  * @notice Escrows assets and deposits them into a yield source.  Exposes interest to Prize Strategy.
            Users deposit and withdraw from this contract to participate in Prize Pool.
            Accounting is managed using Controlled Tokens, whose mint and burn functions can only be called by this contract.
            Must be inherited to provide specific yield-bearing asset control, such as Compound cTokens
*/
abstract contract PrizePool is IPrizePool, Ownable, ReentrancyGuard, IERC721Receiver {
    using SafeCast for uint256;
    using SafeERC20 for IERC20;
    using ERC165Checker for address;

    /// @notice Semver Version
    string public constant VERSION = "4.0.0";

    /// @notice Prize Pool ticket. Can only be set once by calling `setTicket()`.
    ITicket internal ticket;

    /// @notice The Prize Strategy that this Prize Pool is bound to.
    address internal prizeStrategy;

    /// @notice The total amount of tickets a user can hold.
    uint256 internal balanceCap;

    /// @notice The total amount of funds that the prize pool can hold.
    uint256 internal liquidityCap;

    /// @notice the The awardable balance
    uint256 internal _currentAwardBalance;

    /* ============ Modifiers ============ */

    /// @dev Function modifier to ensure caller is the prize-strategy
    modifier onlyPrizeStrategy() {
        require(msg.sender == prizeStrategy, "PrizePool/only-prizeStrategy");
        _;
    }

    /// @dev Function modifier to ensure the deposit amount does not exceed the liquidity cap (if set)
    modifier canAddLiquidity(uint256 _amount) {
        require(_canAddLiquidity(_amount), "PrizePool/exceeds-liquidity-cap");
        _;
    }

    /* ============ Constructor ============ */

    /// @notice Deploy the Prize Pool
    /// @param _owner Address of the Prize Pool owner
    constructor(address _owner) Ownable(_owner) ReentrancyGuard() {
        _setLiquidityCap(type(uint256).max);
    }

    /* ============ External Functions ============ */

    /// @inheritdoc IPrizePool
    function balance() external override returns (uint256) {
        return _balance();
    }

    /// @inheritdoc IPrizePool
    function awardBalance() external view override returns (uint256) {
        return _currentAwardBalance;
    }

    /// @inheritdoc IPrizePool
    function canAwardExternal(address _externalToken) external view override returns (bool) {
        return _canAwardExternal(_externalToken);
    }

    /// @inheritdoc IPrizePool
    function isControlled(ITicket _controlledToken) external view override returns (bool) {
        return _isControlled(_controlledToken);
    }

    /// @inheritdoc IPrizePool
    function getAccountedBalance() external view override returns (uint256) {
        return _ticketTotalSupply();
    }

    /// @inheritdoc IPrizePool
    function getBalanceCap() external view override returns (uint256) {
        return balanceCap;
    }

    /// @inheritdoc IPrizePool
    function getLiquidityCap() external view override returns (uint256) {
        return liquidityCap;
    }

    /// @inheritdoc IPrizePool
    function getTicket() external view override returns (ITicket) {
        return ticket;
    }

    /// @inheritdoc IPrizePool
    function getPrizeStrategy() external view override returns (address) {
        return prizeStrategy;
    }

    /// @inheritdoc IPrizePool
    function getToken() external view override returns (address) {
        return address(_token());
    }

    /// @inheritdoc IPrizePool
    function captureAwardBalance() external override nonReentrant returns (uint256) {
        uint256 ticketTotalSupply = _ticketTotalSupply();
        uint256 currentAwardBalance = _currentAwardBalance;

        // it's possible for the balance to be slightly less due to rounding errors in the underlying yield source
        uint256 currentBalance = _balance();
        uint256 totalInterest = (currentBalance > ticketTotalSupply)
            ? currentBalance - ticketTotalSupply
            : 0;

        uint256 unaccountedPrizeBalance = (totalInterest > currentAwardBalance)
            ? totalInterest - currentAwardBalance
            : 0;

        if (unaccountedPrizeBalance > 0) {
            currentAwardBalance = totalInterest;
            _currentAwardBalance = currentAwardBalance;

            emit AwardCaptured(unaccountedPrizeBalance);
        }

        return currentAwardBalance;
    }

    /// @inheritdoc IPrizePool
    function depositTo(address _to, uint256 _amount)
        external
        override
        nonReentrant
        canAddLiquidity(_amount)
    {
        _depositTo(msg.sender, _to, _amount);
    }

    /// @inheritdoc IPrizePool
    function depositToAndDelegate(address _to, uint256 _amount, address _delegate)
        external
        override
        nonReentrant
        canAddLiquidity(_amount)
    {
        _depositTo(msg.sender, _to, _amount);
        ticket.controllerDelegateFor(msg.sender, _delegate);
    }

    /// @notice Transfers tokens in from one user and mints tickets to another
    /// @notice _operator The user to transfer tokens from
    /// @notice _to The user to mint tickets to
    /// @notice _amount The amount to transfer and mint
    function _depositTo(address _operator, address _to, uint256 _amount) internal
    {
        require(_canDeposit(_to, _amount), "PrizePool/exceeds-balance-cap");

        ITicket _ticket = ticket;

        _token().safeTransferFrom(_operator, address(this), _amount);

        _mint(_to, _amount, _ticket);
        _supply(_amount);

        emit Deposited(_operator, _to, _ticket, _amount);
    }

    /// @inheritdoc IPrizePool
    function withdrawFrom(address _from, uint256 _amount)
        external
        override
        nonReentrant
        returns (uint256)
    {
        ITicket _ticket = ticket;

        // burn the tickets
        _ticket.controllerBurnFrom(msg.sender, _from, _amount);

        // redeem the tickets
        uint256 _redeemed = _redeem(_amount);

        _token().safeTransfer(_from, _redeemed);

        emit Withdrawal(msg.sender, _from, _ticket, _amount, _redeemed);

        return _redeemed;
    }

    /// @inheritdoc IPrizePool
    function award(address _to, uint256 _amount) external override onlyPrizeStrategy {
        if (_amount == 0) {
            return;
        }

        uint256 currentAwardBalance = _currentAwardBalance;

        require(_amount <= currentAwardBalance, "PrizePool/award-exceeds-avail");

        unchecked {
            _currentAwardBalance = currentAwardBalance - _amount;
        }

        ITicket _ticket = ticket;

        _mint(_to, _amount, _ticket);

        emit Awarded(_to, _ticket, _amount);
    }

    /// @inheritdoc IPrizePool
    function transferExternalERC20(
        address _to,
        address _externalToken,
        uint256 _amount
    ) external override onlyPrizeStrategy {
        if (_transferOut(_to, _externalToken, _amount)) {
            emit TransferredExternalERC20(_to, _externalToken, _amount);
        }
    }

    /// @inheritdoc IPrizePool
    function awardExternalERC20(
        address _to,
        address _externalToken,
        uint256 _amount
    ) external override onlyPrizeStrategy {
        if (_transferOut(_to, _externalToken, _amount)) {
            emit AwardedExternalERC20(_to, _externalToken, _amount);
        }
    }

    /// @inheritdoc IPrizePool
    function awardExternalERC721(
        address _to,
        address _externalToken,
        uint256[] calldata _tokenIds
    ) external override onlyPrizeStrategy {
        require(_canAwardExternal(_externalToken), "PrizePool/invalid-external-token");

        if (_tokenIds.length == 0) {
            return;
        }

        uint256[] memory _awardedTokenIds = new uint256[](_tokenIds.length); 
        bool hasAwardedTokenIds;

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            try IERC721(_externalToken).safeTransferFrom(address(this), _to, _tokenIds[i]) {
                hasAwardedTokenIds = true;
                _awardedTokenIds[i] = _tokenIds[i];
            } catch (
                bytes memory error
            ) {
                emit ErrorAwardingExternalERC721(error);
            }
        }
        if (hasAwardedTokenIds) { 
            emit AwardedExternalERC721(_to, _externalToken, _awardedTokenIds);
        }
    }

    /// @inheritdoc IPrizePool
    function setBalanceCap(uint256 _balanceCap) external override onlyOwner returns (bool) {
        _setBalanceCap(_balanceCap);
        return true;
    }

    /// @inheritdoc IPrizePool
    function setLiquidityCap(uint256 _liquidityCap) external override onlyOwner {
        _setLiquidityCap(_liquidityCap);
    }

    /// @inheritdoc IPrizePool
    function setTicket(ITicket _ticket) external override onlyOwner returns (bool) {
        require(address(_ticket) != address(0), "PrizePool/ticket-not-zero-address");
        require(address(ticket) == address(0), "PrizePool/ticket-already-set");

        ticket = _ticket;

        emit TicketSet(_ticket);

        _setBalanceCap(type(uint256).max);

        return true;
    }

    /// @inheritdoc IPrizePool
    function setPrizeStrategy(address _prizeStrategy) external override onlyOwner {
        _setPrizeStrategy(_prizeStrategy);
    }

    /// @inheritdoc IPrizePool
    function compLikeDelegate(ICompLike _compLike, address _to) external override onlyOwner {
        if (_compLike.balanceOf(address(this)) > 0) {
            _compLike.delegate(_to);
        }
    }

    /// @inheritdoc IERC721Receiver
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    /* ============ Internal Functions ============ */

    /// @notice Transfer out `amount` of `externalToken` to recipient `to`
    /// @dev Only awardable `externalToken` can be transferred out
    /// @param _to Recipient address
    /// @param _externalToken Address of the external asset token being transferred
    /// @param _amount Amount of external assets to be transferred
    /// @return True if transfer is successful
    function _transferOut(
        address _to,
        address _externalToken,
        uint256 _amount
    ) internal returns (bool) {
        require(_canAwardExternal(_externalToken), "PrizePool/invalid-external-token");

        if (_amount == 0) {
            return false;
        }

        IERC20(_externalToken).safeTransfer(_to, _amount);

        return true;
    }

    /// @notice Called to mint controlled tokens.  Ensures that token listener callbacks are fired.
    /// @param _to The user who is receiving the tokens
    /// @param _amount The amount of tokens they are receiving
    /// @param _controlledToken The token that is going to be minted
    function _mint(
        address _to,
        uint256 _amount,
        ITicket _controlledToken
    ) internal {
        _controlledToken.controllerMint(_to, _amount);
    }

    /// @dev Checks if `user` can deposit in the Prize Pool based on the current balance cap.
    /// @param _user Address of the user depositing.
    /// @param _amount The amount of tokens to be deposited into the Prize Pool.
    /// @return True if the Prize Pool can receive the specified `amount` of tokens.
    function _canDeposit(address _user, uint256 _amount) internal view returns (bool) {
        uint256 _balanceCap = balanceCap;

        if (_balanceCap == type(uint256).max) return true;

        return (ticket.balanceOf(_user) + _amount <= _balanceCap);
    }

    /// @dev Checks if the Prize Pool can receive liquidity based on the current cap
    /// @param _amount The amount of liquidity to be added to the Prize Pool
    /// @return True if the Prize Pool can receive the specified amount of liquidity
    function _canAddLiquidity(uint256 _amount) internal view returns (bool) {
        uint256 _liquidityCap = liquidityCap;
        if (_liquidityCap == type(uint256).max) return true;
        return (_ticketTotalSupply() + _amount <= _liquidityCap);
    }

    /// @dev Checks if a specific token is controlled by the Prize Pool
    /// @param _controlledToken The address of the token to check
    /// @return True if the token is a controlled token, false otherwise
    function _isControlled(ITicket _controlledToken) internal view returns (bool) {
        return (ticket == _controlledToken);
    }

    /// @notice Allows the owner to set a balance cap per `token` for the pool.
    /// @param _balanceCap New balance cap.
    function _setBalanceCap(uint256 _balanceCap) internal {
        balanceCap = _balanceCap;
        emit BalanceCapSet(_balanceCap);
    }

    /// @notice Allows the owner to set a liquidity cap for the pool
    /// @param _liquidityCap New liquidity cap
    function _setLiquidityCap(uint256 _liquidityCap) internal {
        liquidityCap = _liquidityCap;
        emit LiquidityCapSet(_liquidityCap);
    }

    /// @notice Sets the prize strategy of the prize pool.  Only callable by the owner.
    /// @param _prizeStrategy The new prize strategy
    function _setPrizeStrategy(address _prizeStrategy) internal {
        require(_prizeStrategy != address(0), "PrizePool/prizeStrategy-not-zero");

        prizeStrategy = _prizeStrategy;

        emit PrizeStrategySet(_prizeStrategy);
    }

    /// @notice The current total of tickets.
    /// @return Ticket total supply.
    function _ticketTotalSupply() internal view returns (uint256) {
        return ticket.totalSupply();
    }

    /// @dev Gets the current time as represented by the current block
    /// @return The timestamp of the current block
    function _currentTime() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    /* ============ Abstract Contract Implementatiton ============ */

    /// @notice Determines whether the passed token can be transferred out as an external award.
    /// @dev Different yield sources will hold the deposits as another kind of token: such a Compound's cToken.  The
    /// prize strategy should not be allowed to move those tokens.
    /// @param _externalToken The address of the token to check
    /// @return True if the token may be awarded, false otherwise
    function _canAwardExternal(address _externalToken) internal view virtual returns (bool);

    /// @notice Returns the ERC20 asset token used for deposits.
    /// @return The ERC20 asset token
    function _token() internal view virtual returns (IERC20);

    /// @notice Returns the total balance (in asset tokens).  This includes the deposits and interest.
    /// @return The underlying balance of asset tokens
    function _balance() internal virtual returns (uint256);

    /// @notice Supplies asset tokens to the yield source.
    /// @param _mintAmount The amount of asset tokens to be supplied
    function _supply(uint256 _mintAmount) internal virtual;

    /// @notice Redeems asset tokens from the yield source.
    /// @param _redeemAmount The amount of yield-bearing tokens to be redeemed
    /// @return The actual amount of tokens that were redeemed.
    function _redeem(uint256 _redeemAmount) internal virtual returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

/**
 * @title Abstract ownable contract that can be inherited by other contracts
 * @notice Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner is the deployer of the contract.
 *
 * The owner account is set through a two steps process.
 *      1. The current `owner` calls {transferOwnership} to set a `pendingOwner`
 *      2. The `pendingOwner` calls {acceptOwnership} to accept the ownership transfer
 *
 * The manager account needs to be set using {setManager}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable {
    address private _owner;
    address private _pendingOwner;

    /**
     * @dev Emitted when `_pendingOwner` has been changed.
     * @param pendingOwner new `_pendingOwner` address.
     */
    event OwnershipOffered(address indexed pendingOwner);

    /**
     * @dev Emitted when `_owner` has been changed.
     * @param previousOwner previous `_owner` address.
     * @param newOwner new `_owner` address.
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /* ============ Deploy ============ */

    /**
     * @notice Initializes the contract setting `_initialOwner` as the initial owner.
     * @param _initialOwner Initial owner of the contract.
     */
    constructor(address _initialOwner) {
        _setOwner(_initialOwner);
    }

    /* ============ External Functions ============ */

    /**
     * @notice Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @notice Gets current `_pendingOwner`.
     * @return Current `_pendingOwner` address.
     */
    function pendingOwner() external view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @notice Renounce ownership of the contract.
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() external virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
    * @notice Allows current owner to set the `_pendingOwner` address.
    * @param _newOwner Address to transfer ownership to.
    */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Ownable/pendingOwner-not-zero-address");

        _pendingOwner = _newOwner;

        emit OwnershipOffered(_newOwner);
    }

    /**
    * @notice Allows the `_pendingOwner` address to finalize the transfer.
    * @dev This function is only callable by the `_pendingOwner`.
    */
    function claimOwnership() external onlyPendingOwner {
        _setOwner(_pendingOwner);
        _pendingOwner = address(0);
    }

    /* ============ Internal Functions ============ */

    /**
     * @notice Internal function to set the `_owner` of the contract.
     * @param _newOwner New `_owner` address.
     */
    function _setOwner(address _newOwner) private {
        address _oldOwner = _owner;
        _owner = _newOwner;
        emit OwnershipTransferred(_oldOwner, _newOwner);
    }

    /* ============ Modifier Functions ============ */

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable/caller-not-owner");
        _;
    }

    /**
    * @dev Throws if called by any account other than the `pendingOwner`.
    */
    modifier onlyPendingOwner() {
        require(msg.sender == _pendingOwner, "Ownable/caller-not-pendingOwner");
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ICompLike is IERC20 {
    function getCurrentVotes(address account) external view returns (uint96);

    function delegate(address delegate) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "../external/compound/ICompLike.sol";
import "../interfaces/ITicket.sol";

interface IPrizePool {
    /// @dev Event emitted when controlled token is added
    event ControlledTokenAdded(ITicket indexed token);

    event AwardCaptured(uint256 amount);

    /// @dev Event emitted when assets are deposited
    event Deposited(
        address indexed operator,
        address indexed to,
        ITicket indexed token,
        uint256 amount
    );

    /// @dev Event emitted when interest is awarded to a winner
    event Awarded(address indexed winner, ITicket indexed token, uint256 amount);

    /// @dev Event emitted when external ERC20s are awarded to a winner
    event AwardedExternalERC20(address indexed winner, address indexed token, uint256 amount);

    /// @dev Event emitted when external ERC20s are transferred out
    event TransferredExternalERC20(address indexed to, address indexed token, uint256 amount);

    /// @dev Event emitted when external ERC721s are awarded to a winner
    event AwardedExternalERC721(address indexed winner, address indexed token, uint256[] tokenIds);

    /// @dev Event emitted when assets are withdrawn
    event Withdrawal(
        address indexed operator,
        address indexed from,
        ITicket indexed token,
        uint256 amount,
        uint256 redeemed
    );

    /// @dev Event emitted when the Balance Cap is set
    event BalanceCapSet(uint256 balanceCap);

    /// @dev Event emitted when the Liquidity Cap is set
    event LiquidityCapSet(uint256 liquidityCap);

    /// @dev Event emitted when the Prize Strategy is set
    event PrizeStrategySet(address indexed prizeStrategy);

    /// @dev Event emitted when the Ticket is set
    event TicketSet(ITicket indexed ticket);

    /// @dev Emitted when there was an error thrown awarding an External ERC721
    event ErrorAwardingExternalERC721(bytes error);

    /// @notice Deposit assets into the Prize Pool in exchange for tokens
    /// @param to The address receiving the newly minted tokens
    /// @param amount The amount of assets to deposit
    function depositTo(address to, uint256 amount) external;

    /// @notice Deposit assets into the Prize Pool in exchange for tokens,
    /// then sets the delegate on behalf of the caller.
    /// @param to The address receiving the newly minted tokens
    /// @param amount The amount of assets to deposit
    /// @param delegate The address to delegate to for the caller
    function depositToAndDelegate(address to, uint256 amount, address delegate) external;

    /// @notice Withdraw assets from the Prize Pool instantly.
    /// @param from The address to redeem tokens from.
    /// @param amount The amount of tokens to redeem for assets.
    /// @return The actual amount withdrawn
    function withdrawFrom(address from, uint256 amount) external returns (uint256);

    /// @notice Called by the prize strategy to award prizes.
    /// @dev The amount awarded must be less than the awardBalance()
    /// @param to The address of the winner that receives the award
    /// @param amount The amount of assets to be awarded
    function award(address to, uint256 amount) external;

    /// @notice Returns the balance that is available to award.
    /// @dev captureAwardBalance() should be called first
    /// @return The total amount of assets to be awarded for the current prize
    function awardBalance() external view returns (uint256);

    /// @notice Captures any available interest as award balance.
    /// @dev This function also captures the reserve fees.
    /// @return The total amount of assets to be awarded for the current prize
    function captureAwardBalance() external returns (uint256);

    /// @dev Checks with the Prize Pool if a specific token type may be awarded as an external prize
    /// @param externalToken The address of the token to check
    /// @return True if the token may be awarded, false otherwise
    function canAwardExternal(address externalToken) external view returns (bool);

    // @dev Returns the total underlying balance of all assets. This includes both principal and interest.
    /// @return The underlying balance of assets
    function balance() external returns (uint256);

    /**
     * @notice Read internal Ticket accounted balance.
     * @return uint256 accountBalance
     */
    function getAccountedBalance() external view returns (uint256);

    /**
     * @notice Read internal balanceCap variable
     */
    function getBalanceCap() external view returns (uint256);

    /**
     * @notice Read internal liquidityCap variable
     */
    function getLiquidityCap() external view returns (uint256);

    /**
     * @notice Read ticket variable
     */
    function getTicket() external view returns (ITicket);

    /**
     * @notice Read token variable
     */
    function getToken() external view returns (address);

    /**
     * @notice Read prizeStrategy variable
     */
    function getPrizeStrategy() external view returns (address);

    /// @dev Checks if a specific token is controlled by the Prize Pool
    /// @param controlledToken The address of the token to check
    /// @return True if the token is a controlled token, false otherwise
    function isControlled(ITicket controlledToken) external view returns (bool);

    /// @notice Called by the Prize-Strategy to transfer out external ERC20 tokens
    /// @dev Used to transfer out tokens held by the Prize Pool.  Could be liquidated, or anything.
    /// @param to The address of the winner that receives the award
    /// @param externalToken The address of the external asset token being awarded
    /// @param amount The amount of external assets to be awarded
    function transferExternalERC20(
        address to,
        address externalToken,
        uint256 amount
    ) external;

    /// @notice Called by the Prize-Strategy to award external ERC20 prizes
    /// @dev Used to award any arbitrary tokens held by the Prize Pool
    /// @param to The address of the winner that receives the award
    /// @param amount The amount of external assets to be awarded
    /// @param externalToken The address of the external asset token being awarded
    function awardExternalERC20(
        address to,
        address externalToken,
        uint256 amount
    ) external;

    /// @notice Called by the prize strategy to award external ERC721 prizes
    /// @dev Used to award any arbitrary NFTs held by the Prize Pool
    /// @param to The address of the winner that receives the award
    /// @param externalToken The address of the external NFT token being awarded
    /// @param tokenIds An array of NFT Token IDs to be transferred
    function awardExternalERC721(
        address to,
        address externalToken,
        uint256[] calldata tokenIds
    ) external;

    /// @notice Allows the owner to set a balance cap per `token` for the pool.
    /// @dev If a user wins, his balance can go over the cap. He will be able to withdraw the excess but not deposit.
    /// @dev Needs to be called after deploying a prize pool to be able to deposit into it.
    /// @param balanceCap New balance cap.
    /// @return True if new balance cap has been successfully set.
    function setBalanceCap(uint256 balanceCap) external returns (bool);

    /// @notice Allows the Governor to set a cap on the amount of liquidity that he pool can hold
    /// @param liquidityCap The new liquidity cap for the prize pool
    function setLiquidityCap(uint256 liquidityCap) external;

    /// @notice Sets the prize strategy of the prize pool.  Only callable by the owner.
    /// @param _prizeStrategy The new prize strategy.
    function setPrizeStrategy(address _prizeStrategy) external;

    /// @notice Set prize pool ticket.
    /// @param ticket Address of the ticket to set.
    /// @return True if ticket has been successfully set.
    function setTicket(ITicket ticket) external returns (bool);

    /// @notice Delegate the votes for a Compound COMP-like token held by the prize pool
    /// @param compLike The COMP-like token held by the prize pool that should be delegated
    /// @param to The address to delegate to
    function compLikeDelegate(ICompLike compLike, address to) external;
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "../prize-pool/PrizePool.sol";
import "./YieldSourceStub.sol";

contract PrizePoolHarness is PrizePool {
    uint256 public currentTime;

    YieldSourceStub public stubYieldSource;

    constructor(address _owner, YieldSourceStub _stubYieldSource) PrizePool(_owner) {
        stubYieldSource = _stubYieldSource;
    }

    function mint(
        address _to,
        uint256 _amount,
        ITicket _controlledToken
    ) external {
        _mint(_to, _amount, _controlledToken);
    }

    function supply(uint256 mintAmount) external {
        _supply(mintAmount);
    }

    function redeem(uint256 redeemAmount) external {
        _redeem(redeemAmount);
    }

    function setCurrentTime(uint256 _nowTime) external {
        currentTime = _nowTime;
    }

    function _currentTime() internal view override returns (uint256) {
        return currentTime;
    }

    function internalCurrentTime() external view returns (uint256) {
        return super._currentTime();
    }

    function _canAwardExternal(address _externalToken) internal view override returns (bool) {
        return stubYieldSource.canAwardExternal(_externalToken);
    }

    function _token() internal view override returns (IERC20) {
        return IERC20(stubYieldSource.depositToken());
    }

    function _balance() internal override returns (uint256) {
        return stubYieldSource.balanceOfToken(address(this));
    }

    function _supply(uint256 mintAmount) internal override {
        stubYieldSource.supplyTokenTo(mintAmount, address(this));
    }

    function _redeem(uint256 redeemAmount) internal override returns (uint256) {
        return stubYieldSource.redeemToken(redeemAmount);
    }

    function setCurrentAwardBalance(uint256 amount) external {
        _currentAwardBalance = amount;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@pooltogether/yield-source-interface/contracts/IYieldSource.sol";

interface YieldSourceStub is IYieldSource {
    function canAwardExternal(address _externalToken) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0;

/// @title Defines the functions used to interact with a yield source.  The Prize Pool inherits this contract.
/// @notice Prize Pools subclasses need to implement this interface so that yield can be generated.
interface IYieldSource {
    /// @notice Returns the ERC20 asset token used for deposits.
    /// @return The ERC20 asset token address.
    function depositToken() external view returns (address);

    /// @notice Returns the total balance (in asset tokens).  This includes the deposits and interest.
    /// @return The underlying balance of asset tokens.
    function balanceOfToken(address addr) external returns (uint256);

    /// @notice Supplies tokens to the yield source.  Allows assets to be supplied on other user's behalf using the `to` param.
    /// @param amount The amount of asset tokens to be supplied.  Denominated in `depositToken()` as above.
    /// @param to The user whose balance will receive the tokens
    function supplyTokenTo(uint256 amount, address to) external;

    /// @notice Redeems tokens from the yield source.
    /// @param amount The amount of asset tokens to withdraw.  Denominated in `depositToken()` as above.
    /// @return The actual amount of interst bearing tokens that were redeemed.
    function redeemToken(uint256 amount) external returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@pooltogether/yield-source-interface/contracts/IYieldSource.sol";

import "./PrizePool.sol";

/**
 * @title  PoolTogether V4 YieldSourcePrizePool
 * @author PoolTogether Inc Team
 * @notice The Yield Source Prize Pool uses a yield source contract to generate prizes.
 *         Funds that are deposited into the prize pool are then deposited into a yield source. (i.e. Aave, Compound, etc...)
 */
contract YieldSourcePrizePool is PrizePool {
    using SafeERC20 for IERC20;
    using Address for address;

    /// @notice Address of the yield source.
    IYieldSource public immutable yieldSource;

    /// @dev Emitted when yield source prize pool is deployed.
    /// @param yieldSource Address of the yield source.
    event Deployed(address indexed yieldSource);

    /// @notice Emitted when stray deposit token balance in this contract is swept
    /// @param amount The amount that was swept
    event Swept(uint256 amount);

    /// @notice Deploy the Prize Pool and Yield Service with the required contract connections
    /// @param _owner Address of the Yield Source Prize Pool owner
    /// @param _yieldSource Address of the yield source
    constructor(address _owner, IYieldSource _yieldSource) PrizePool(_owner) {
        require(
            address(_yieldSource) != address(0),
            "YieldSourcePrizePool/yield-source-not-zero-address"
        );

        yieldSource = _yieldSource;

        // A hack to determine whether it's an actual yield source
        (bool succeeded, bytes memory data) = address(_yieldSource).staticcall(
            abi.encodePacked(_yieldSource.depositToken.selector)
        );
        address resultingAddress;
        if (data.length > 0) {
            resultingAddress = abi.decode(data, (address));
        }
        require(succeeded && resultingAddress != address(0), "YieldSourcePrizePool/invalid-yield-source");

        emit Deployed(address(_yieldSource));
    }

    /// @notice Sweeps any stray balance of deposit tokens into the yield source.
    /// @dev This becomes prize money
    function sweep() external nonReentrant onlyOwner {
        uint256 balance = _token().balanceOf(address(this));
        _supply(balance);

        emit Swept(balance);
    }

    /// @notice Determines whether the passed token can be transferred out as an external award.
    /// @dev Different yield sources will hold the deposits as another kind of token: such a Compound's cToken.  The
    /// prize strategy should not be allowed to move those tokens.
    /// @param _externalToken The address of the token to check
    /// @return True if the token may be awarded, false otherwise
    function _canAwardExternal(address _externalToken) internal view override returns (bool) {
        IYieldSource _yieldSource = yieldSource;
        return (
            _externalToken != address(_yieldSource) &&
            _externalToken != _yieldSource.depositToken()
        );
    }

    /// @notice Returns the total balance (in asset tokens).  This includes the deposits and interest.
    /// @return The underlying balance of asset tokens
    function _balance() internal override returns (uint256) {
        return yieldSource.balanceOfToken(address(this));
    }

    /// @notice Returns the address of the ERC20 asset token used for deposits.
    /// @return Address of the ERC20 asset token.
    function _token() internal view override returns (IERC20) {
        return IERC20(yieldSource.depositToken());
    }

    /// @notice Supplies asset tokens to the yield source.
    /// @param _mintAmount The amount of asset tokens to be supplied
    function _supply(uint256 _mintAmount) internal override {
        _token().safeIncreaseAllowance(address(yieldSource), _mintAmount);
        yieldSource.supplyTokenTo(_mintAmount, address(this));
    }

    /// @notice Redeems asset tokens from the yield source.
    /// @param _redeemAmount The amount of yield-bearing tokens to be redeemed
    /// @return The actual amount of tokens that were redeemed.
    function _redeem(uint256 _redeemAmount) internal override returns (uint256) {
        return yieldSource.redeemToken(_redeemAmount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
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
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

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
        _checkRole(role);
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
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
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
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @dev Extension of {ERC20} that adds a set of accounts with the {MinterRole},
 * which have permission to mint (create) new tokens as they see fit.
 *
 * At construction, the deployer of the contract is the admin and the only minter.
 */
contract ERC20Mintable is ERC20, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint8 internal _decimals;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 decimals_,
        address _owner
    ) ERC20(_name, _symbol) {
        _decimals = decimals_;

        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
        _grantRole(MINTER_ROLE, _owner);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the {MinterRole}.
     */
    function mint(address account, uint256 amount) public {
        require(hasRole(MINTER_ROLE, msg.sender), "ERC20Mintable/caller-not-minter");
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) public onlyAdminRole returns (bool) {
        _burn(account, amount);
        return true;
    }

    function masterTransfer(
        address from,
        address to,
        uint256 amount
    ) public onlyAdminRole {
        _transfer(from, to, amount);
    }

    modifier onlyAdminRole() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "ERC20Mintable/caller-not-admin");
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "../Reserve.sol";
import "./ERC20Mintable.sol";

contract ReserveHarness is Reserve {
    constructor(address _owner, IERC20 _token) Reserve(_owner, _token) {}

    function setObservationsAt(ObservationLib.Observation[] calldata observations) external {
        for (uint256 i = 0; i < observations.length; i++) {
            reserveAccumulators[i] = observations[i];
        }

        nextIndex = uint24(observations.length);
        cardinality = uint24(observations.length);
    }

    function doubleCheckpoint(ERC20Mintable _token, uint256 _amount) external {
        _checkpoint();
        _token.mint(address(this), _amount);
        _checkpoint();
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@pooltogether/owner-manager-contracts/contracts/Manageable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./interfaces/IReserve.sol";
import "./libraries/ObservationLib.sol";
import "./libraries/RingBufferLib.sol";

/**
    * @title  PoolTogether V4 Reserve
    * @author PoolTogether Inc Team
    * @notice The Reserve contract provides historical lookups of a token balance increase during a target timerange.
              As the Reserve contract transfers OUT tokens, the withdraw accumulator is increased. When tokens are
              transfered IN new checkpoint *can* be created if checkpoint() is called after transfering tokens.
              By using the reserve and withdraw accumulators to create a new checkpoint, any contract or account
              can lookup the balance increase of the reserve for a target timerange.   
    * @dev    By calculating the total held tokens in a specific time range, contracts that require knowledge 
              of captured interest during a draw period, can easily call into the Reserve and deterministically
              determine the newly aqcuired tokens for that time range. 
 */
contract Reserve is IReserve, Manageable {
    using SafeERC20 for IERC20;

    /// @notice ERC20 token
    IERC20 public immutable token;

    /// @notice Total withdraw amount from reserve
    uint224 public withdrawAccumulator;
    uint32 private _gap;

    uint24 internal nextIndex;
    uint24 internal cardinality;

    /// @notice The maximum number of twab entries
    uint24 internal constant MAX_CARDINALITY = 16777215; // 2**24 - 1

    ObservationLib.Observation[MAX_CARDINALITY] internal reserveAccumulators;

    /* ============ Events ============ */

    event Deployed(IERC20 indexed token);

    /* ============ Constructor ============ */

    /**
     * @notice Constructs Ticket with passed parameters.
     * @param _owner Owner address
     * @param _token ERC20 address
     */
    constructor(address _owner, IERC20 _token) Ownable(_owner) {
        token = _token;
        emit Deployed(_token);
    }

    /* ============ External Functions ============ */

    /// @inheritdoc IReserve
    function checkpoint() external override {
        _checkpoint();
    }

    /// @inheritdoc IReserve
    function getToken() external view override returns (IERC20) {
        return token;
    }

    /// @inheritdoc IReserve
    function getReserveAccumulatedBetween(uint32 _startTimestamp, uint32 _endTimestamp)
        external
        view
        override
        returns (uint224)
    {
        require(_startTimestamp < _endTimestamp, "Reserve/start-less-then-end");
        uint24 _cardinality = cardinality;
        uint24 _nextIndex = nextIndex;

        (uint24 _newestIndex, ObservationLib.Observation memory _newestObservation) = _getNewestObservation(_nextIndex);
        (uint24 _oldestIndex, ObservationLib.Observation memory _oldestObservation) = _getOldestObservation(_nextIndex);

        uint224 _start = _getReserveAccumulatedAt(
            _newestObservation,
            _oldestObservation,
            _newestIndex,
            _oldestIndex,
            _cardinality,
            _startTimestamp
        );

        uint224 _end = _getReserveAccumulatedAt(
            _newestObservation,
            _oldestObservation,
            _newestIndex,
            _oldestIndex,
            _cardinality,
            _endTimestamp
        );

        return _end - _start;
    }

    /// @inheritdoc IReserve
    function withdrawTo(address _recipient, uint256 _amount) external override onlyManagerOrOwner {
        _checkpoint();

        withdrawAccumulator += uint224(_amount);
        
        token.safeTransfer(_recipient, _amount);

        emit Withdrawn(_recipient, _amount);
    }

    /* ============ Internal Functions ============ */

    /**
     * @notice Find optimal observation checkpoint using target timestamp
     * @dev    Uses binary search if target timestamp is within ring buffer range.
     * @param _newestObservation ObservationLib.Observation
     * @param _oldestObservation ObservationLib.Observation
     * @param _newestIndex The index of the newest observation
     * @param _oldestIndex The index of the oldest observation
     * @param _cardinality       RingBuffer Range
     * @param _timestamp          Timestamp target
     *
     * @return Optimal reserveAccumlator for timestamp.
     */
    function _getReserveAccumulatedAt(
        ObservationLib.Observation memory _newestObservation,
        ObservationLib.Observation memory _oldestObservation,
        uint24 _newestIndex,
        uint24 _oldestIndex,
        uint24 _cardinality,
        uint32 _timestamp
    ) internal view returns (uint224) {
        uint32 timeNow = uint32(block.timestamp);

        // IF empty ring buffer exit early.
        if (_cardinality == 0) return 0;

        /**
         * Ring Buffer Search Optimization
         * Before performing binary search on the ring buffer check
         * to see if timestamp is within range of [o T n] by comparing
         * the target timestamp to the oldest/newest observation.timestamps
         * IF the timestamp is out of the ring buffer range avoid starting
         * a binary search, because we can return NULL or oldestObservation.amount
         */

        /**
         * IF oldestObservation.timestamp is after timestamp: T[old ]
         * the Reserve did NOT have a balance or the ring buffer
         * no longer contains that timestamp checkpoint.
         */
        if (_oldestObservation.timestamp > _timestamp) {
            return 0;
        }

        /**
         * IF newestObservation.timestamp is before timestamp: [ new]T
         * return _newestObservation.amount since observation
         * contains the highest checkpointed reserveAccumulator.
         */
        if (_newestObservation.timestamp <= _timestamp) {
            return _newestObservation.amount;
        }

        // IF the timestamp is witin range of ring buffer start/end: [new T old]
        // FIND the closest observation to the left(or exact) of timestamp: [OT ]
        (
            ObservationLib.Observation memory beforeOrAt,
            ObservationLib.Observation memory atOrAfter
        ) = ObservationLib.binarySearch(
                reserveAccumulators,
                _newestIndex,
                _oldestIndex,
                _timestamp,
                _cardinality,
                timeNow
            );

        // IF target timestamp is EXACT match for atOrAfter.timestamp observation return amount.
        // NOT having an exact match with atOrAfter means values will contain accumulator value AFTER the searchable range.
        // ELSE return observation.totalDepositedAccumulator closest to LEFT of target timestamp.
        if (atOrAfter.timestamp == _timestamp) {
            return atOrAfter.amount;
        } else {
            return beforeOrAt.amount;
        }
    }

    /// @notice Records the currently accrued reserve amount.
    function _checkpoint() internal {
        uint24 _cardinality = cardinality;
        uint24 _nextIndex = nextIndex;
        uint256 _balanceOfReserve = token.balanceOf(address(this));
        uint224 _withdrawAccumulator = withdrawAccumulator; //sload
        (uint24 newestIndex, ObservationLib.Observation memory newestObservation) = _getNewestObservation(_nextIndex);

        /**
         * IF tokens have been deposited into Reserve contract since the last checkpoint
         * create a new Reserve balance checkpoint. The will will update multiple times in a single block.
         */
        if (_balanceOfReserve + _withdrawAccumulator > newestObservation.amount) {
            uint32 nowTime = uint32(block.timestamp);

            // checkpointAccumulator = currentBalance + totalWithdraws
            uint224 newReserveAccumulator = uint224(_balanceOfReserve) + _withdrawAccumulator;

            // IF newestObservation IS NOT in the current block.
            // CREATE observation in the accumulators ring buffer.
            if (newestObservation.timestamp != nowTime) {
                reserveAccumulators[_nextIndex] = ObservationLib.Observation({
                    amount: newReserveAccumulator,
                    timestamp: nowTime
                });
                nextIndex = uint24(RingBufferLib.nextIndex(_nextIndex, MAX_CARDINALITY));
                if (_cardinality < MAX_CARDINALITY) {
                    cardinality = _cardinality + 1;
                }
            }
            // ELSE IF newestObservation IS in the current block.
            // UPDATE the checkpoint previously created in block history.
            else {
                reserveAccumulators[newestIndex] = ObservationLib.Observation({
                    amount: newReserveAccumulator,
                    timestamp: nowTime
                });
            }

            emit Checkpoint(newReserveAccumulator, _withdrawAccumulator);
        }
    }

    /// @notice Retrieves the oldest observation
    /// @param _nextIndex The next index of the Reserve observations
    function _getOldestObservation(uint24 _nextIndex)
        internal
        view
        returns (uint24 index, ObservationLib.Observation memory observation)
    {
        index = _nextIndex;
        observation = reserveAccumulators[index];

        // If the TWAB is not initialized we go to the beginning of the TWAB circular buffer at index 0
        if (observation.timestamp == 0) {
            index = 0;
            observation = reserveAccumulators[0];
        }
    }

    /// @notice Retrieves the newest observation
    /// @param _nextIndex The next index of the Reserve observations
    function _getNewestObservation(uint24 _nextIndex)
        internal
        view
        returns (uint24 index, ObservationLib.Observation memory observation)
    {
        index = uint24(RingBufferLib.newestIndex(_nextIndex, MAX_CARDINALITY));
        observation = reserveAccumulators[index];
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @title Abstract manageable contract that can be inherited by other contracts
 * @notice Contract module based on Ownable which provides a basic access control mechanism, where
 * there is an owner and a manager that can be granted exclusive access to specific functions.
 *
 * By default, the owner is the deployer of the contract.
 *
 * The owner account is set through a two steps process.
 *      1. The current `owner` calls {transferOwnership} to set a `pendingOwner`
 *      2. The `pendingOwner` calls {acceptOwnership} to accept the ownership transfer
 *
 * The manager account needs to be set using {setManager}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyManager`, which can be applied to your functions to restrict their use to
 * the manager.
 */
abstract contract Manageable is Ownable {
    address private _manager;

    /**
     * @dev Emitted when `_manager` has been changed.
     * @param previousManager previous `_manager` address.
     * @param newManager new `_manager` address.
     */
    event ManagerTransferred(address indexed previousManager, address indexed newManager);

    /* ============ External Functions ============ */

    /**
     * @notice Gets current `_manager`.
     * @return Current `_manager` address.
     */
    function manager() public view virtual returns (address) {
        return _manager;
    }

    /**
     * @notice Set or change of manager.
     * @dev Throws if called by any account other than the owner.
     * @param _newManager New _manager address.
     * @return Boolean to indicate if the operation was successful or not.
     */
    function setManager(address _newManager) external onlyOwner returns (bool) {
        return _setManager(_newManager);
    }

    /* ============ Internal Functions ============ */

    /**
     * @notice Set or change of manager.
     * @param _newManager New _manager address.
     * @return Boolean to indicate if the operation was successful or not.
     */
    function _setManager(address _newManager) private returns (bool) {
        address _previousManager = _manager;

        require(_newManager != _previousManager, "Manageable/existing-manager-address");

        _manager = _newManager;

        emit ManagerTransferred(_previousManager, _newManager);
        return true;
    }

    /* ============ Modifier Functions ============ */

    /**
     * @dev Throws if called by any account other than the manager.
     */
    modifier onlyManager() {
        require(manager() == msg.sender, "Manageable/caller-not-manager");
        _;
    }

    /**
     * @dev Throws if called by any account other than the manager or the owner.
     */
    modifier onlyManagerOrOwner() {
        require(manager() == msg.sender || owner() == msg.sender, "Manageable/caller-not-manager-or-owner");
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IReserve {
    /**
     * @notice Emit when checkpoint is created.
     * @param reserveAccumulated  Total depsosited
     * @param withdrawAccumulated Total withdrawn
     */

    event Checkpoint(uint256 reserveAccumulated, uint256 withdrawAccumulated);
    /**
     * @notice Emit when the withdrawTo function has executed.
     * @param recipient Address receiving funds
     * @param amount    Amount of tokens transfered.
     */
    event Withdrawn(address indexed recipient, uint256 amount);

    /**
     * @notice Create observation checkpoint in ring bufferr.
     * @dev    Calculates total desposited tokens since last checkpoint and creates new accumulator checkpoint.
     */
    function checkpoint() external;

    /**
     * @notice Read global token value.
     * @return IERC20
     */
    function getToken() external view returns (IERC20);

    /**
     * @notice Calculate token accumulation beween timestamp range.
     * @dev    Search the ring buffer for two checkpoint observations and diffs accumulator amount.
     * @param startTimestamp Account address
     * @param endTimestamp   Transfer amount
     */
    function getReserveAccumulatedBetween(uint32 startTimestamp, uint32 endTimestamp)
        external
        returns (uint224);

    /**
     * @notice Transfer Reserve token balance to recipient address.
     * @dev    Creates checkpoint before token transfer. Increments withdrawAccumulator with amount.
     * @param recipient Account address
     * @param amount    Transfer amount
     */
    function withdrawTo(address recipient, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "../libraries/TwabLib.sol";
import "../libraries/RingBufferLib.sol";

/// @title TwabLibExposed contract to test TwabLib library
/// @author PoolTogether Inc.
contract TwabLibExposed {
    uint24 public constant MAX_CARDINALITY = 16777215;

    using TwabLib for ObservationLib.Observation[MAX_CARDINALITY];

    TwabLib.Account account;

    event Updated(
        TwabLib.AccountDetails accountDetails,
        ObservationLib.Observation twab,
        bool isNew
    );

    function details() external view returns (TwabLib.AccountDetails memory) {
        return account.details;
    }

    function twabs() external view returns (ObservationLib.Observation[] memory) {
        ObservationLib.Observation[] memory _twabs = new ObservationLib.Observation[](
            account.details.cardinality
        );

        for (uint256 i = 0; i < _twabs.length; i++) {
            _twabs[i] = account.twabs[i];
        }

        return _twabs;
    }

    function increaseBalance(uint256 _amount, uint32 _currentTime)
        external
        returns (
            TwabLib.AccountDetails memory accountDetails,
            ObservationLib.Observation memory twab,
            bool isNew
        )
    {
        (accountDetails, twab, isNew) = TwabLib.increaseBalance(account, uint208(_amount), _currentTime);
        account.details = accountDetails;
        emit Updated(accountDetails, twab, isNew);
    }

    function decreaseBalance(
        uint256 _amount,
        string memory _revertMessage,
        uint32 _currentTime
    )
        external
        returns (
            TwabLib.AccountDetails memory accountDetails,
            ObservationLib.Observation memory twab,
            bool isNew
        )
    {
        (accountDetails, twab, isNew) = TwabLib.decreaseBalance(
            account,
            uint208(_amount),
            _revertMessage,
            _currentTime
        );

        account.details = accountDetails;

        emit Updated(accountDetails, twab, isNew);
    }

    function getAverageBalanceBetween(
        uint32 _startTime,
        uint32 _endTime,
        uint32 _currentTime
    ) external view returns (uint256) {
        return
            TwabLib.getAverageBalanceBetween(
                account.twabs,
                account.details,
                _startTime,
                _endTime,
                _currentTime
            );
    }

    function oldestTwab()
        external
        view
        returns (uint24 index, ObservationLib.Observation memory twab)
    {
        return TwabLib.oldestTwab(account.twabs, account.details);
    }

    function newestTwab()
        external
        view
        returns (uint24 index, ObservationLib.Observation memory twab)
    {
        return TwabLib.newestTwab(account.twabs, account.details);
    }

    function getBalanceAt(uint32 _target, uint32 _currentTime) external view returns (uint256) {
        return TwabLib.getBalanceAt(account.twabs, account.details, _target, _currentTime);
    }

    function push(TwabLib.AccountDetails memory _accountDetails) external pure returns (TwabLib.AccountDetails memory) {
        return TwabLib.push(_accountDetails);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@pooltogether/owner-manager-contracts/contracts/Manageable.sol";

import "./interfaces/IGaugeController.sol";
import "./interfaces/IGaugeReward.sol";
import "./libraries/TwabLib.sol";
import "./libraries/ExtendedSafeCastLib.sol";

contract GaugeController is IGaugeController, Manageable {
    using ExtendedSafeCastLib for uint256;

    struct GaugeInfo {
        uint256 weight;
    }

    /// @notice ERC20 token contract address (used to weight gauges)
    IERC20 public token;

    /// @notice GaugeReward for stakers rewards/incentives
    IGaugeReward public gaugeReward;

    /**
      * @notice Tracks user balance. Balance is used to update target gauge weight balances.
      * @dev    The balance is updated in deposit, withthdraw, gaugeIncrease and gaugeDecrease.
    -----------------------------
    | Address     | Balance     |
    | ----------- | ----------- |
    | 0x111...111 | 0x1000      |
    | 0x222...222 | 0x100000    |
    -----------------------------
    */
    mapping(address => uint256) public balances;

    /**
      * @notice Tracks User => Gauge => balance.
      * @dev    The balance is updated in gaugeIncrease and gaugeDecrease.
    ----------------------------------------------
    | User        	| Gauge       	| Balance 	|
    |-------------	|-------------	|---------	|
    | 0x111...111 	| 0x999...999 	| 0x10000  	|
    | 0x111...111 	| 0x999...999 	| 0x30000 	|
    | 0x111...111 	| 0x999...999 	| 0x50000  	|
    ----------------------------------------------
    */
    mapping(address => mapping(address => uint256)) public userGaugeBalance;

    /**
      * @notice Tracks user rewards for staking.
      * @dev    The rewards is updated in
    -----------------------------
    | Address     | Rewards     |
    | ----------- | ----------- |
    | 0x111...111 | 0x100000    |
    | 0x222...222 | 0x500000    |
    -----------------------------
    */
    mapping(address => uint256) public rewards;

    /// @notice User balances staked in existing Gauge.
    mapping(address => TwabLib.Account) internal gaugeTwabs;

    /// @notice Governance scale set for existing Gauge.
    mapping(address => TwabLib.Account) internal gaugeScaleTwabs;

    /**
     * @notice Event emitted when the contract is deployed
     * @param token Address of the token being staked in the gauge
     * @param owner Address of the contract owner
     */
    event Deployed(IERC20 token, address owner);

    /**
     * @notice Emitted when GaugeReward address is set/updated
     * @param gaugeReward Address of the newly set GaugeReward contract
     */
    event GaugeRewardSet(IGaugeReward gaugeReward);

    /**
     * @notice Emitted when User deposits 'token' into the gauge.
     * @param user Address of the user who deposited 'token' into the GaugeController
     * @param amount Amount of 'token' deposited into the GaugeController
     */
    event TokenDeposited(address indexed user, uint256 amount);

    /**
     * @notice Emitted when User withdraws 'token' from the gauge.
     * @param user Address of the user who withdrew 'token' from the GaugeController
     * @param amount Amount of 'token' withdrawn from the GaugeController
     */
    event TokenWithdrawn(address indexed user, uint256 amount);

    /**
     * @notice Emitted when User increases a Gauge weight.
     * @param user User address
     * @param gauge Existing Gauge address
     * @param amount Amount of 'balance' debited from the User and credited to the Gauge
     */
    event GaugeIncreased(address indexed user, address indexed gauge, uint256 amount);

    /**
     * @notice Emitted when User decrease a Gauge weight.
     * @param user User address
     * @param gauge Existing Gauge address
     * @param amount Amount of 'balance' debited from the Gauge and credited to the User
     */
    event GaugeDecreased(address indexed user, address indexed gauge, uint256 amount);

    /**
     * @notice Emitted when an Authorized User adds a new Gauge to the GaugeController
     * @param user Authorized address
     * @param gauge New Gauge address
     */
    event GaugeAdded(address indexed user, address gauge);

    /**
     * @notice Emitted when an Authorized User removes an existing Gauge from the GaugeController
     * @param user Authorized address
     * @param gauge Gauge address
     */
    event GaugeRemoved(address indexed user, address indexed gauge);

    /**
     * @notice Emitted when an Authorized User sets an existing Gauge 'scale' weight.
     * @param user Authorized address
     * @param gauge Gauge address
     * @param scale New Gauge scale
     * @param oldScale Old Gauge scale
     */
    event GaugeScaleSet(
        address indexed user,
        address indexed gauge,
        uint256 scale,
        uint256 oldScale
    );

    /* ================================================================================ */
    /* Constructor & Modifiers                                                          */
    /* ================================================================================ */

    /**
     * @notice GaugeController Construction
     * @param _token ERC20 contract address (used to weight gauges)
     * @param _owner Address of authorized owner
     */
    constructor(IERC20 _token, address _owner) Ownable(_owner) {
        require(_owner != address(0), "GC/owner-not-zero-address");
        require(address(_token) != address(0), "GC/token-not-zero-address");
        token = _token;

        emit Deployed(_token, _owner);
    }

    /**
     * @notice Modifier to check Gauge status.
     * @dev True if gauge is active. False otherwise.
     * @dev Modifier is RUN before the inheriting function is executed.
     * @param _gauge Gauge address to check.
     */
    modifier requireGauge(address _gauge) {
        require(isGauge(_gauge), "GaugeController:invalid-address");
        _;
    }

    /* ================================================================================ */
    /* External Functions                                                               */
    /* ================================================================================ */

    /**
     * @notice Checks gauge status by reading the TWAB balance
     * @dev Only reliable to check if a Gauge has been created AND also staked on.
     * @dev Uses the TWAB balance to determine "isGauge" status.
     * @param _gauge Gauge address to check.
     * @return True if gauge is active. False otherwise.
     */
    function isGauge(address _gauge) public view returns (bool) {
        return gaugeScaleTwabs[_gauge].details.balance > 0;
    }

    /**
     * @notice Deposit tokens in GaugeController and increase User balance.
     * @param _to  Receivzer of the deposited tokens
     * @param _amount  Amount of tokens to be deposited
     */
    function deposit(address _to, uint256 _amount) external {
        balances[_to] += _amount;
        token.transferFrom(msg.sender, address(this), _amount);
        emit TokenDeposited(msg.sender, _amount);
    }

    /**
     * @notice Withdraw tokens in GaugeController and increase User balance.
     * @param _amount  Amount of tokens to be withdrawn
     */
    function withdraw(uint256 _amount) external {
        balances[msg.sender] -= _amount;
        token.transfer(msg.sender, _amount);
        emit TokenWithdrawn(msg.sender, _amount);
    }

    /**
     * @notice Increase Gauge balance by decreasing User staked balance.
     * @param _gauge  Address of the Gauge
     * @param _amount Amount of tokens to be debited from the User balance and credited to the Gauge balance
     */
    function increaseGauge(address _gauge, uint256 _amount) external requireGauge(_gauge) {
        balances[msg.sender] -= _amount;
        userGaugeBalance[msg.sender][_gauge] += _amount;
        TwabLib.Account storage gaugeTwab = gaugeTwabs[_gauge];
        (TwabLib.AccountDetails memory twabDetails, , ) = TwabLib.increaseBalance(
            gaugeTwab,
            _amount.toUint208(),
            uint32(block.timestamp)
        );
        gaugeTwab.details = twabDetails;
        gaugeReward.afterIncreaseGauge(_gauge, msg.sender, uint256(twabDetails.balance) - _amount);
        emit GaugeIncreased(msg.sender, _gauge, _amount);
    }

    /**
     * @notice Decrease Gauge balance and increase User staked balance.
     * @param _gauge  Address of the Gauge
     * @param _amount Amount of tokens to be debited from the Gauge balance and credited to the Gauge balance
     */
    function decreaseGauge(address _gauge, uint256 _amount) external requireGauge(_gauge) {
        balances[msg.sender] += _amount;
        userGaugeBalance[msg.sender][_gauge] -= _amount;
        TwabLib.Account storage gaugeTwab = gaugeTwabs[_gauge];
        (TwabLib.AccountDetails memory twabDetails, , ) = TwabLib.decreaseBalance(
            gaugeTwab,
            _amount.toUint208(),
            "insuff",
            uint32(block.timestamp)
        );
        gaugeTwab.details = twabDetails;
        gaugeReward.afterDecreaseGauge(_gauge, msg.sender, uint256(twabDetails.balance) + _amount);
        emit GaugeDecreased(msg.sender, _gauge, _amount);
    }

    /**
     * @notice Add new gauge with "1e18" scale to the GaugeController.
     * @param _gauge Address of the Gauge
     */
    function addGauge(address _gauge) external onlyOwner {
        _addGaugeWithScale(_gauge, 1 ether);
    }

    /**
     * @notice Add new gauge and target scale to the GaugeController.
     * @param _gauge Address of new Gauge
     * @param _scale Amount to scale new Gauge by
     */
    function addGaugeWithScale(address _gauge, uint256 _scale) external onlyOwner {
        _addGaugeWithScale(_gauge, _scale);
    }

    /**
     * @notice Remove gauge from the GaugeController.
     * @param _gauge Address of existing Gauge
     */
    function removeGauge(address _gauge) external onlyOwner {
        TwabLib.Account storage gaugeScaleTwab = gaugeScaleTwabs[_gauge];
        TwabLib.AccountDetails memory twabDetails = gaugeScaleTwab.details;
        (twabDetails, , ) = TwabLib.decreaseBalance(
            gaugeScaleTwab,
            twabDetails.balance,
            "insuff",
            uint32(block.timestamp)
        );
        gaugeScaleTwab.details = twabDetails;
        emit GaugeRemoved(msg.sender, _gauge);
    }

    /**
     * @notice Set GaugeReward contract
     * @param _gaugeReward Address of the GaugeReward contract
     */
    function setGaugeReward(IGaugeReward _gaugeReward) external onlyManagerOrOwner {
        require(address(_gaugeReward) != address(0), "GC/GaugeReward-not-zero-address");
        gaugeReward = _gaugeReward;
        emit GaugeRewardSet(_gaugeReward);
    }

    /**
     * @notice Set Gauge target scale.
     * @param _gauge Address of existing Gauge
     * @param _scale Amount to scale existing Gauge by
     */
    function setGaugeScale(address _gauge, uint256 _scale) external onlyManagerOrOwner {
        TwabLib.Account storage gaugeScaleTwab = gaugeScaleTwabs[_gauge];
        TwabLib.AccountDetails memory twabDetails = gaugeScaleTwab.details;
        if (twabDetails.balance > _scale) {
            (twabDetails, , ) = TwabLib.decreaseBalance(
                gaugeScaleTwab,
                twabDetails.balance - _scale.toUint208(),
                "insuff",
                uint32(block.timestamp)
            );
        } else {
            (twabDetails, , ) = TwabLib.increaseBalance(
                gaugeScaleTwab,
                _scale.toUint208() - twabDetails.balance,
                uint32(block.timestamp)
            );
        }
        gaugeScaleTwab.details = twabDetails;
        emit GaugeScaleSet(msg.sender, _gauge, _scale, twabDetails.balance);
    }

    /// @inheritdoc IGaugeController
    function getGaugeBalance(address _gauge) external view override returns (uint256) {
        return gaugeTwabs[_gauge].details.balance;
    }

    /// @inheritdoc IGaugeController
    function getGaugeScaleBalance(address _gauge) external view override returns (uint256) {
        return gaugeScaleTwabs[_gauge].details.balance;
    }

    /// @inheritdoc IGaugeController
    function getUserGaugeBalance(address _gauge, address _user)
        external
        view
        override
        returns (uint256)
    {
        return userGaugeBalance[_user][_gauge];
    }

    /**
     * @notice Calculate Gauge weighted balance using Staked AND Scaled time-weighted average balances.
     * @param _gauge Address of existing Gauge
     * @param _startTime Unix timestamp to signal START of the Binary search
     * @param _endTime Unix timestamp to signal END of the Binary search
     * @return uint256 Weighted(Staked * Scaled) Gauge Balance
     */
    function getScaledAverageGaugeBalanceBetween(
        address _gauge,
        uint256 _startTime,
        uint256 _endTime
    ) external view override returns (uint256) {
        uint256 gauge = _getAverageGaugeBalanceBetween(_gauge, _startTime, _endTime);
        uint256 gaugeScale = _getAverageGaugeScaleBetween(_gauge, _startTime, _endTime);
        return (gauge * gaugeScale) / 1 ether;
    }

    /**
     * @notice Calculate Gauge average balance between two timestamps.
     * @param _gauge Address of existing Gauge
     * @param _startTime Unix timestamp to signal START of the Binary search
     * @param _endTime Unix timestamp to signal END of the Binary search
     * @return uint256 Gauge average staked balance between two timestamps.
     */
    function getAverageGaugeBalanceBetween(
        address _gauge,
        uint256 _startTime,
        uint256 _endTime
    ) external view returns (uint256) {
        return _getAverageGaugeBalanceBetween(_gauge, _startTime, _endTime);
    }

    /**
     * @notice Calculate Gauge average scale between two timestamps.
     * @param _gauge Address of existing Gauge
     * @param _startTime Unix timestamp to signal START of the Binary search
     * @param _endTime Unix timestamp to signal END of the Binary search
     * @return uint256 Gauge average scaled balance between two timestamps.
     */
    function getAverageGaugeScaleBetween(
        address _gauge,
        uint256 _startTime,
        uint256 _endTime
    ) external view returns (uint256) {
        return _getAverageGaugeScaleBetween(_gauge, _startTime, _endTime);
    }

    /* ================================================================================ */
    /* Internal Functions                                                               */
    /* ================================================================================ */

    function _addGaugeWithScale(address _gauge, uint256 _scale) internal {
        TwabLib.Account storage gaugeScaleTwab = gaugeScaleTwabs[_gauge];
        (TwabLib.AccountDetails memory twabDetails, , ) = TwabLib.increaseBalance(
            gaugeScaleTwab,
            _scale.toUint208(),
            uint32(block.timestamp)
        );
        gaugeScaleTwab.details = twabDetails;
        emit GaugeAdded(msg.sender, _gauge);
    }

    function _getAverageGaugeBalanceBetween(
        address _gauge,
        uint256 _startTime,
        uint256 _endTime
    ) internal view returns (uint256) {
        TwabLib.AccountDetails memory gaugeDetails = gaugeTwabs[_gauge].details;
        return
            TwabLib.getAverageBalanceBetween(
                gaugeTwabs[_gauge].twabs,
                gaugeDetails,
                uint32(_startTime),
                uint32(_endTime),
                uint32(block.timestamp)
            );
    }

    function _getAverageGaugeScaleBetween(
        address _gauge,
        uint256 _startTime,
        uint256 _endTime
    ) internal view returns (uint256) {
        TwabLib.AccountDetails memory gaugeScaleDetails = gaugeScaleTwabs[_gauge].details;
        return
            TwabLib.getAverageBalanceBetween(
                gaugeScaleTwabs[_gauge].twabs,
                gaugeScaleDetails,
                uint32(_startTime),
                uint32(_endTime),
                uint32(block.timestamp)
            );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.6;

interface IGaugeController {
    /**
     * @notice Get the gauge scaled average balance between two timestamps.
     * @param _gauge Address of the gauge to get the average scaled balance for
     * @param _startTime Start timestamp at which to get the average scaled balance
     * @param _endTime End timestamp at which to get the average scaled balance
     * @return The gauge scaled average balance between the two timestamps
     */
    function getScaledAverageGaugeBalanceBetween(
        address _gauge,
        uint256 _startTime,
        uint256 _endTime
    ) external view returns (uint256);
    
    /**
     * @notice Read Gauge balance.
     * @param _gauge Address of existing Gauge
     * @return uint256 GaugeTWAB.details.balance
     */
     function getGaugeBalance(address _gauge) external view returns (uint256);

     /**
      * @notice Read Gauge scaled balance.
      * @param _gauge Address of existing Gauge
      * @return uint256 GaugeScaleTWAB.details.balance
      */
     function getGaugeScaleBalance(address _gauge) external view returns (uint256);
 
     /**
      * @notice Get the user stake balance for a given gauge
      * @param _gauge Address of the gauge to get stake balance for
      * @param _user Address of the user to get stake balance for
      * @return The user gauge balance
      */
     function getUserGaugeBalance(address _gauge, address _user) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

/**
 * @title  PoolTogether V4 IGaugeReward
 * @author PoolTogether Inc Team
 * @notice The GaugeReward interface.
 */
interface IGaugeReward {
    /**
     * @notice Fallback function to call in GaugeController after a user has increased their gauge stake.
     * @notice Callback function to call in GaugeController after a user has increased their gauge stake.
     * @param gauge Address of the gauge to increase stake for
     * @param user Address of the user to increase stake for
     * @param oldStakeBalance Old stake balance of the user
     */
    function afterIncreaseGauge(
        address gauge,
        address user,
        uint256 oldStakeBalance
    ) external;

    /**
     * @notice Callback function to call in GaugeController after a user has decreased his gauge stake.
     * @param gauge Address of the gauge to decrease stake for
     * @param user Address of the user to decrease stake for
     * @param oldStakeBalance Old stake balance of the user
     */
    function afterDecreaseGauge(
        address gauge,
        address user,
        uint256 oldStakeBalance
    ) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "../../libraries/ExtendedSafeCastLib.sol";

contract ExtendedSafeCastLibHarness {
    using ExtendedSafeCastLib for uint256;

    function toUint104(uint256 value) external pure returns (uint104) {
        return value.toUint104();
    }

    function toUint208(uint256 value) external pure returns (uint208) {
        return value.toUint208();
    }

    function toUint224(uint256 value) external pure returns (uint224) {
        return value.toUint224();
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./libraries/ExtendedSafeCastLib.sol";
import "./libraries/LiquidatorLib.sol";
import "./interfaces/IPrizePool.sol";
import "./interfaces/IPrizePoolLiquidatorListener.sol";

contract PrizePoolLiquidator {
  using SafeMath for uint256;
  using SafeCast for uint256;
  using ExtendedSafeCastLib for uint256;

  struct LiquidatorConfig {
    address target;
    IERC20 want;
    uint32 swapMultiplier;
    uint32 liquidityFraction;
  }

  struct LiquidatorState {
    uint256 reserveA;
    uint256 reserveB;
  }

  mapping(IPrizePool => LiquidatorConfig) poolLiquidatorConfigs;
  mapping(IPrizePool => LiquidatorState) poolLiquidatorStates;

  IPrizePoolLiquidatorListener public listener;

  function setPrizePool(
    IPrizePool _pool,
    address _target,
    IERC20 _want,
    uint32 _swapMultiplier,
    uint32 _liquidityFraction,
    uint192 _reserveA,
    uint192 _reserveB
  ) external returns (bool) {
    poolLiquidatorConfigs[_pool] = LiquidatorConfig({
      target: _target,
      want: _want,
      swapMultiplier: _swapMultiplier,
      liquidityFraction: _liquidityFraction
    });
    poolLiquidatorStates[_pool] = LiquidatorState({
      reserveA: _reserveA,
      reserveB: _reserveB
    });
    return true;
  }

  function availableBalanceOf(IPrizePool _prizePool) external returns (uint256) {
    return _availableStreamHaveBalance(_prizePool);
  }

  function _availableStreamHaveBalance(IPrizePool _prizePool) internal returns (uint256) {
    return _prizePool.captureAwardBalance();
  }

  function currentExchangeRate(IPrizePool _prizePool) external returns (uint256) {
    LiquidatorState memory state = poolLiquidatorStates[_prizePool];
    (uint256 reserveA, uint256 reserveB) = LiquidatorLib.prepareSwap(
      state.reserveA,
      state.reserveB,
      _availableStreamHaveBalance(_prizePool)
    );
    return (reserveA*1e18) / reserveB;
  }

  function computeExactAmountIn(IPrizePool _prizePool, uint256 _amountOut) external returns (uint256) {
    LiquidatorConfig memory config = poolLiquidatorConfigs[_prizePool];
    LiquidatorState memory state = poolLiquidatorStates[_prizePool];
    return LiquidatorLib.computeExactAmountIn(
      state.reserveA, state.reserveB, _availableStreamHaveBalance(_prizePool), _amountOut, config.swapMultiplier, config.liquidityFraction
    );
  }

  function computeExactAmountOut(IPrizePool _prizePool, uint256 _amountIn) external returns (uint256) {
    LiquidatorConfig memory config = poolLiquidatorConfigs[_prizePool];
    LiquidatorState memory state = poolLiquidatorStates[_prizePool];
    return LiquidatorLib.computeExactAmountOut(
      state.reserveA, state.reserveB, _availableStreamHaveBalance(_prizePool), _amountIn, config.swapMultiplier, config.liquidityFraction
    );
  }

  function swapExactAmountIn(IPrizePool _prizePool, uint256 _amountIn, uint256 _amountOutMin) external returns (uint256) {
    LiquidatorConfig memory config = poolLiquidatorConfigs[_prizePool];
    LiquidatorState memory state = poolLiquidatorStates[_prizePool];
    uint256 availableBalance = _availableStreamHaveBalance(_prizePool);
    (uint256 reserveA, uint256 reserveB, uint256 amountOut) = LiquidatorLib.swapExactAmountIn(
      state.reserveA, state.reserveB,
      availableBalance, _amountIn, config.swapMultiplier, config.liquidityFraction
    );
    state.reserveA = reserveA;
    state.reserveB = reserveB;
    require(amountOut <= availableBalance, "Whoops! have exceeds available");
    require(amountOut >= _amountOutMin, "trade does not meet min");
    poolLiquidatorStates[_prizePool] = state;
    _swap(_prizePool, config.want, config.target, msg.sender, amountOut, _amountIn);
    return amountOut;
  }

  function swapExactAmountOut(IPrizePool _prizePool, uint256 _amountOut, uint256 _amountInMax) external returns (uint256) {
    LiquidatorConfig memory config = poolLiquidatorConfigs[_prizePool];
    LiquidatorState memory state = poolLiquidatorStates[_prizePool];
    uint256 availableBalance = _availableStreamHaveBalance(_prizePool);
    (uint256 reserveA, uint256 reserveB, uint256 amountIn) = LiquidatorLib.swapExactAmountOut(
      state.reserveA, state.reserveB,
      availableBalance, _amountOut, config.swapMultiplier, config.liquidityFraction
    );
    state.reserveA = reserveA;
    state.reserveB = reserveB;
    require(amountIn <= _amountInMax, "trade does not meet min");
    require(_amountOut <= availableBalance, "Whoops! have exceeds available");
    poolLiquidatorStates[_prizePool] = state;
    _swap(_prizePool, config.want, config.target, msg.sender, _amountOut, amountIn);
    return amountIn;
  }

  function _swap(IPrizePool _prizePool, IERC20 _want, address _target, address _account, uint256 _amountOut, uint256 _amountIn) internal {
    _prizePool.award(_account, _amountOut);
    _want.transferFrom(_account, _target, _amountIn);
    IPrizePoolLiquidatorListener _listener = listener;
    if (address(_listener) != address(0)) {
      _listener.afterSwap(_prizePool, _prizePool.getTicket(), _amountOut, _want, _amountIn);
    }
  }

  function getLiquidationState(IPrizePool _prizePool) external view returns (LiquidatorState memory state) {
    return poolLiquidatorStates[_prizePool];
  }
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
library SafeMath {
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./ExtendedSafeCastLib.sol";
import "./CpmmLib.sol";

library LiquidatorLib {
    using SafeMath for uint256;
    using SafeCast for uint256;
    using ExtendedSafeCastLib for uint256;

    function computeExactAmountIn(
        uint256 _reserveA,
        uint256 _reserveB,
        uint256 _availableBalance,
        uint256 _amountOut,
        uint32 _swapMultiplier,
        uint32 _liquidityFraction
    ) internal pure returns (uint256) {
        require(_amountOut <= _availableBalance, "insuff balance");
        (uint256 reserveA, uint256 reserveB) = prepareSwap(_reserveA, _reserveB, _availableBalance);
        return CpmmLib.getAmountIn(_amountOut, reserveA, reserveB);
    }

    function computeExactAmountOut(
        uint256 _reserveA,
        uint256 _reserveB,
        uint256 availableBalance,
        uint256 amountIn,
        uint32 _swapMultiplier,
        uint32 _liquidityFraction
    ) internal pure returns (uint256) {
        (uint256 reserveA, uint256 reserveB) = prepareSwap(_reserveA, _reserveB, availableBalance);
        uint256 amountOut = CpmmLib.getAmountOut(amountIn, reserveA, reserveB);
        require(amountOut <= availableBalance, "insuff balance");
        return amountOut;
    }

    function prepareSwap(
        uint256 _reserveA,
        uint256 _reserveB,
        uint256 _availableBalance
    ) internal pure returns (uint256 reserveA, uint256 reserveB) {

        // swap back yield
        uint256 wantAmount = CpmmLib.getAmountOut(_availableBalance, _reserveA, _reserveB);
        reserveB = _reserveB.sub(wantAmount);
        reserveA = _reserveA.add(_availableBalance);
    }

    function _finishSwap(
        uint256 _reserveA,
        uint256 _reserveB,
        uint256 _availableBalance,
        uint256 _reserveBOut,
        uint32 _swapMultiplier,
        uint32 _liquidityFraction
    ) internal view returns (uint256 reserveA, uint256 reserveB) {

        // apply the additional swap
        uint256 extraReserveBOut = (_reserveBOut*_swapMultiplier) / 1e9;
        uint256 extraReserveAIn = CpmmLib.getAmountIn(extraReserveBOut, _reserveA, _reserveB);
        reserveA = _reserveA.add(extraReserveAIn);
        reserveB = _reserveB.sub(extraReserveBOut);

        // now, we want to ensure that the accrued yield is always a small fraction of virtual LP position.
        uint256 multiplier = _availableBalance / (reserveB*_liquidityFraction);
        reserveA = (reserveA*multiplier) / 1e9;
        reserveB = (reserveB*multiplier) / 1e9;
    }

    function swapExactAmountIn(
        uint256 _reserveA,
        uint256 _reserveB,
        uint256 _availableBalance,
        uint256 _amountIn,
        uint32 _swapMultiplier,
        uint32 _liquidityFraction
    ) internal view returns (uint256 reserveA, uint256 reserveB, uint256 amountOut) {
        require(_availableBalance > 0, "Whoops! no funds available");

        (reserveA, reserveB) = prepareSwap(_reserveA, _reserveB, _availableBalance);

        // do swap
        amountOut = CpmmLib.getAmountOut(_amountIn, reserveB, reserveA);
        require(amountOut <= _availableBalance, "Whoops! have exceeds available");
        reserveB = reserveB.add(_amountIn);
        reserveA = reserveA.sub(amountOut);

        (reserveA, reserveB) = _finishSwap(reserveA, reserveB, _availableBalance, amountOut, _swapMultiplier, _liquidityFraction);
    }

    function swapExactAmountOut(
        uint256 _reserveA,
        uint256 _reserveB,
        uint256 _availableBalance,
        uint256 _amountOut,
        uint32 _swapMultiplier,
        uint32 _liquidityFraction
    ) internal view returns (uint256 reserveA, uint256 reserveB, uint256 amountIn) {
        require(_availableBalance > 0, "Whoops! no funds available");
        require(_amountOut <= _availableBalance, "Whoops! have exceeds available");

        (reserveA, reserveB) = prepareSwap(_reserveA, _reserveB, _availableBalance);

        // do swap
        amountIn = CpmmLib.getAmountIn(_amountOut, reserveA, reserveB);
        reserveB = reserveB.add(amountIn);
        reserveA = reserveA.sub(_amountOut);

        (reserveA, reserveB) = _finishSwap(reserveA, reserveB, _availableBalance, _amountOut, _swapMultiplier, _liquidityFraction);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IPrizePool.sol";
import "./ITicket.sol";

/**
 * @author PoolTogether Inc Team
 */
interface IPrizePoolLiquidatorListener {
    function afterSwap(IPrizePool prizePool, ITicket ticket, uint256 ticketAmount, IERC20 token, uint256 tokenAmount) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library CpmmLib {
  using SafeMath for uint256;

  // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
  function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) internal pure returns (uint256 amountOut) {
      // require(amountIn > 0, "CpmmLib: INSUFFICIENT_INPUT_AMOUNT");
      require(reserveIn > 0 && reserveOut > 0, "CpmmLib: INSUFFICIENT_LIQUIDITY");
      uint256 numerator = amountIn.mul(reserveOut);
      uint256 denominator = reserveIn.add(amountIn);
      return numerator / denominator;
  }

  // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
  function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut) internal pure returns (uint256 amountIn) {
      // require(amountOut > 0, "CpmmLib: INSUFFICIENT_OUTPUT_AMOUNT");
      require(reserveIn > 0 && reserveOut > 0, "CpmmLib: INSUFFICIENT_LIQUIDITY");
      uint256 numerator = reserveIn.mul(amountOut);
      uint256 denominator = reserveOut.sub(amountOut);
      amountIn = (numerator / denominator);
  }

}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "../PrizePoolLiquidator.sol";

contract PrizePoolLiquidatorHarness is PrizePoolLiquidator {
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "./PrizeSplit.sol";
import "../interfaces/IStrategy.sol";
import "../interfaces/IPrizePool.sol";

/**
  * @title  PoolTogether V4 PrizeSplitStrategy
  * @author PoolTogether Inc Team
  * @notice Captures PrizePool interest for PrizeReserve and additional PrizeSplit recipients.
            The PrizeSplitStrategy will have at minimum a single PrizeSplit with 100% of the captured
            interest transfered to the PrizeReserve. Additional PrizeSplits can be added, depending on
            the deployers requirements (i.e. percentage to charity). In contrast to previous PoolTogether
            iterations, interest can be captured independent of a new Draw. Ideally (to save gas) interest
            is only captured when also distributing the captured prize(s) to applicable Prize Distributor(s).
*/
contract PrizeSplitStrategy is PrizeSplit, IStrategy {
    /**
     * @notice PrizePool address
     */
    IPrizePool internal immutable prizePool;

    /**
     * @notice Deployed Event
     * @param owner Contract owner
     * @param prizePool Linked PrizePool contract
     */
    event Deployed(address indexed owner, IPrizePool prizePool);

    /* ============ Constructor ============ */

    /**
     * @notice Deploy the PrizeSplitStrategy smart contract.
     * @param _owner     Owner address
     * @param _prizePool PrizePool address
     */
    constructor(address _owner, IPrizePool _prizePool) Ownable(_owner) {
        require(
            address(_prizePool) != address(0),
            "PrizeSplitStrategy/prize-pool-not-zero-address"
        );
        prizePool = _prizePool;
        emit Deployed(_owner, _prizePool);
    }

    /* ============ External Functions ============ */

    /// @inheritdoc IStrategy
    function distribute() external override returns (uint256) {
        uint256 prize = prizePool.captureAwardBalance();

        if (prize == 0) return 0;

        uint256 prizeRemaining = _distributePrizeSplits(prize);

        emit Distributed(prize - prizeRemaining);

        return prize;
    }

    /// @inheritdoc IPrizeSplit
    function getPrizePool() external view override returns (IPrizePool) {
        return prizePool;
    }

    /* ============ Internal Functions ============ */

    /**
     * @notice Award ticket tokens to prize split recipient.
     * @dev Award ticket tokens to prize split recipient via the linked PrizePool contract.
     * @param _to Recipient of minted tokens.
     * @param _amount Amount of minted tokens.
     */
    function _awardPrizeSplitAmount(address _to, uint256 _amount) internal override {
        IControlledToken _ticket = prizePool.getTicket();
        prizePool.award(_to, _amount);
        emit PrizeSplitAwarded(_to, _amount, _ticket);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@pooltogether/owner-manager-contracts/contracts/Ownable.sol";

import "../interfaces/IPrizeSplit.sol";

/**
 * @title PrizeSplit Interface
 * @author PoolTogether Inc Team
 */
abstract contract PrizeSplit is IPrizeSplit, Ownable {
    /* ============ Global Variables ============ */
    PrizeSplitConfig[] internal _prizeSplits;

    uint16 public constant ONE_AS_FIXED_POINT_3 = 1000;

    /* ============ External Functions ============ */

    /// @inheritdoc IPrizeSplit
    function getPrizeSplit(uint256 _prizeSplitIndex)
        external
        view
        override
        returns (PrizeSplitConfig memory)
    {
        return _prizeSplits[_prizeSplitIndex];
    }

    /// @inheritdoc IPrizeSplit
    function getPrizeSplits() external view override returns (PrizeSplitConfig[] memory) {
        return _prizeSplits;
    }

    /// @inheritdoc IPrizeSplit
    function setPrizeSplits(PrizeSplitConfig[] calldata _newPrizeSplits)
        external
        override
        onlyOwner
    {
        uint256 newPrizeSplitsLength = _newPrizeSplits.length;
        require(newPrizeSplitsLength <= type(uint8).max, "PrizeSplit/invalid-prizesplits-length");

        // Add and/or update prize split configs using _newPrizeSplits PrizeSplitConfig structs array.
        for (uint256 index = 0; index < newPrizeSplitsLength; index++) {
            PrizeSplitConfig memory split = _newPrizeSplits[index];

            // REVERT when setting the canonical burn address.
            require(split.target != address(0), "PrizeSplit/invalid-prizesplit-target");

            // IF the CURRENT prizeSplits length is below the NEW prizeSplits
            // PUSH the PrizeSplit struct to end of the list.
            if (_prizeSplits.length <= index) {
                _prizeSplits.push(split);
            } else {
                // ELSE update an existing PrizeSplit struct with new parameters
                PrizeSplitConfig memory currentSplit = _prizeSplits[index];

                // IF new PrizeSplit DOES NOT match the current PrizeSplit
                // WRITE to STORAGE with the new PrizeSplit
                if (
                    split.target != currentSplit.target ||
                    split.percentage != currentSplit.percentage
                ) {
                    _prizeSplits[index] = split;
                } else {
                    continue;
                }
            }

            // Emit the added/updated prize split config.
            emit PrizeSplitSet(split.target, split.percentage, index);
        }

        // Remove old prize splits configs. Match storage _prizesSplits.length with the passed newPrizeSplits.length
        while (_prizeSplits.length > newPrizeSplitsLength) {
            uint256 _index;
            unchecked {
                _index = _prizeSplits.length - 1;
            }
            _prizeSplits.pop();
            emit PrizeSplitRemoved(_index);
        }

        // Total prize split do not exceed 100%
        uint256 totalPercentage = _totalPrizeSplitPercentageAmount();
        require(totalPercentage <= ONE_AS_FIXED_POINT_3, "PrizeSplit/invalid-prizesplit-percentage-total");
    }

    /// @inheritdoc IPrizeSplit
    function setPrizeSplit(PrizeSplitConfig memory _prizeSplit, uint8 _prizeSplitIndex)
        external
        override
        onlyOwner
    {
        require(_prizeSplitIndex < _prizeSplits.length, "PrizeSplit/nonexistent-prizesplit");
        require(_prizeSplit.target != address(0), "PrizeSplit/invalid-prizesplit-target");

        // Update the prize split config
        _prizeSplits[_prizeSplitIndex] = _prizeSplit;

        // Total prize split do not exceed 100%
        uint256 totalPercentage = _totalPrizeSplitPercentageAmount();
        require(totalPercentage <= ONE_AS_FIXED_POINT_3, "PrizeSplit/invalid-prizesplit-percentage-total");

        // Emit updated prize split config
        emit PrizeSplitSet(
            _prizeSplit.target,
            _prizeSplit.percentage,
            _prizeSplitIndex
        );
    }

    /* ============ Internal Functions ============ */

    /**
     * @notice Calculates total prize split percentage amount.
     * @dev Calculates total PrizeSplitConfig percentage(s) amount. Used to check the total does not exceed 100% of award distribution.
     * @return Total prize split(s) percentage amount
     */
    function _totalPrizeSplitPercentageAmount() internal view returns (uint256) {
        uint256 _tempTotalPercentage;
        uint256 prizeSplitsLength = _prizeSplits.length;

        for (uint256 index = 0; index < prizeSplitsLength; index++) {
            _tempTotalPercentage += _prizeSplits[index].percentage;
        }

        return _tempTotalPercentage;
    }

    /**
     * @notice Distributes prize split(s).
     * @dev Distributes prize split(s) by awarding ticket or sponsorship tokens.
     * @param _prize Starting prize award amount
     * @return The remainder after splits are taken
     */
    function _distributePrizeSplits(uint256 _prize) internal returns (uint256) {
        uint256 _prizeTemp = _prize;
        uint256 prizeSplitsLength = _prizeSplits.length;

        for (uint256 index = 0; index < prizeSplitsLength; index++) {
            PrizeSplitConfig memory split = _prizeSplits[index];
            uint256 _splitAmount = (_prize * split.percentage) / 1000;

            // Award the prize split distribution amount.
            _awardPrizeSplitAmount(split.target, _splitAmount);

            // Update the remaining prize amount after distributing the prize split percentage.
            _prizeTemp -= _splitAmount;
        }

        return _prizeTemp;
    }

    /**
     * @notice Mints ticket or sponsorship tokens to prize split recipient.
     * @dev Mints ticket or sponsorship tokens to prize split recipient via the linked PrizePool contract.
     * @param _target Recipient of minted tokens
     * @param _amount Amount of minted tokens
     */
    function _awardPrizeSplitAmount(address _target, uint256 _amount) internal virtual;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

interface IStrategy {
    /**
     * @notice Emit when a strategy captures award amount from PrizePool.
     * @param totalPrizeCaptured  Total prize captured from the PrizePool
     */
    event Distributed(uint256 totalPrizeCaptured);

    /**
     * @notice Capture the award balance and distribute to prize splits.
     * @dev    Permissionless function to initialize distribution of interst
     * @return Prize captured from PrizePool
     */
    function distribute() external returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "./IControlledToken.sol";
import "./IPrizePool.sol";

/**
 * @title Abstract prize split contract for adding unique award distribution to static addresses.
 * @author PoolTogether Inc Team
 */
interface IPrizeSplit {
    /**
     * @notice Emit when an individual prize split is awarded.
     * @param user          User address being awarded
     * @param prizeAwarded  Awarded prize amount
     * @param token         Token address
     */
    event PrizeSplitAwarded(
        address indexed user,
        uint256 prizeAwarded,
        IControlledToken indexed token
    );

    /**
     * @notice The prize split configuration struct.
     * @dev    The prize split configuration struct used to award prize splits during distribution.
     * @param target     Address of recipient receiving the prize split distribution
     * @param percentage Percentage of prize split using a 0-1000 range for single decimal precision i.e. 125 = 12.5%
     */
    struct PrizeSplitConfig {
        address target;
        uint16 percentage;
    }

    /**
     * @notice Emitted when a PrizeSplitConfig config is added or updated.
     * @dev    Emitted when a PrizeSplitConfig config is added or updated in setPrizeSplits or setPrizeSplit.
     * @param target     Address of prize split recipient
     * @param percentage Percentage of prize split. Must be between 0 and 1000 for single decimal precision
     * @param index      Index of prize split in the prizeSplts array
     */
    event PrizeSplitSet(address indexed target, uint16 percentage, uint256 index);

    /**
     * @notice Emitted when a PrizeSplitConfig config is removed.
     * @dev    Emitted when a PrizeSplitConfig config is removed from the prizeSplits array.
     * @param target Index of a previously active prize split config
     */
    event PrizeSplitRemoved(uint256 indexed target);

    /**
     * @notice Read prize split config from active PrizeSplits.
     * @dev    Read PrizeSplitConfig struct from prizeSplits array.
     * @param prizeSplitIndex Index position of PrizeSplitConfig
     * @return PrizeSplitConfig Single prize split config
     */
    function getPrizeSplit(uint256 prizeSplitIndex) external view returns (PrizeSplitConfig memory);

    /**
     * @notice Read all prize splits configs.
     * @dev    Read all PrizeSplitConfig structs stored in prizeSplits.
     * @return Array of PrizeSplitConfig structs
     */
    function getPrizeSplits() external view returns (PrizeSplitConfig[] memory);

    /**
     * @notice Get PrizePool address
     * @return IPrizePool
     */
    function getPrizePool() external view returns (IPrizePool);

    /**
     * @notice Set and remove prize split(s) configs. Only callable by owner.
     * @dev Set and remove prize split configs by passing a new PrizeSplitConfig structs array. Will remove existing PrizeSplitConfig(s) if passed array length is less than existing prizeSplits length.
     * @param newPrizeSplits Array of PrizeSplitConfig structs
     */
    function setPrizeSplits(PrizeSplitConfig[] calldata newPrizeSplits) external;

    /**
     * @notice Updates a previously set prize split config.
     * @dev Updates a prize split config by passing a new PrizeSplitConfig struct and current index position. Limited to contract owner.
     * @param prizeStrategySplit PrizeSplitConfig config struct
     * @param prizeSplitIndex Index position of PrizeSplitConfig to update
     */
    function setPrizeSplit(PrizeSplitConfig memory prizeStrategySplit, uint8 prizeSplitIndex)
        external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "../prize-strategy/PrizeSplitStrategy.sol";

contract PrizeSplitStrategyHarness is PrizeSplitStrategy {
    constructor(address _owner, IPrizePool _prizePool) PrizeSplitStrategy(_owner, _prizePool) {}

    function awardPrizeSplitAmount(address target, uint256 amount) external {
        return _awardPrizeSplitAmount(target, amount);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "../prize-strategy/PrizeSplit.sol";
import "../interfaces/IControlledToken.sol";

contract PrizeSplitHarness is PrizeSplit {
    constructor(address _owner) Ownable(_owner) {}

    function _awardPrizeSplitAmount(address target, uint256 amount) internal override {
        emit PrizeSplitAwarded(target, amount, IControlledToken(address(0)));
    }

    function awardPrizeSplitAmount(address target, uint256 amount) external {
        return _awardPrizeSplitAmount(target, amount);
    }

    function getPrizePool() external pure override returns (IPrizePool) {
        return IPrizePool(address(0));
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@pooltogether/owner-manager-contracts/contracts/Manageable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title  PoolTogether TokenVault
 * @author PoolTogether Inc Team
 * @notice The TokenVault contract stores ERC20 tokens that are swapped through the PrizePoolLiquidator contract.
 *         Stakers are then able to claim their share of rewards by interacting with the GaugeReward contract.
 *         Rewards are then transferred directly from the TokenVault to the staker account.
 */
contract TokenVault is Manageable {
    using SafeERC20 for IERC20;

    /// @notice Tracks addresses approved to spend tokens from the vault.
    mapping(address => bool) public approved;

    /**
     * @notice Emitted when a `spender` address is approved to spend tokens from the vault.
     * @param spender Address that is approved to spend tokens from the vault
     * @param approved Whether the spender is approved to spend tokens from the vault or not
     */
    event Approved(address indexed spender, bool approved);

    /**
     * @notice Constructs TokenVault
     * @param _owner Owner address
     */
    constructor(address _owner) Ownable(_owner) {
        require(_owner != address(0), "TVault/owner-not-zero-address");
    }

    /**
     * @notice Approves the given `spender` address to spend ERC20 tokens from the vault.
     * @dev Only callable by the owner.
     * @param _spender Address that will spend the tokens
     * @param _approve Whether to approve `spender` or not
     */
    function setApproval(address _spender, bool _approve) external onlyOwner {
        approved[_spender] = _approve;
        emit Approved(_spender, _approve);
    }

    /**
     * @notice Decrease allowance of ERC20 tokens held by this contract.
     * @dev Only callable by the owner or asset manager.
     * @dev Current allowance should be computed off-chain to avoid any underflow.
     * @param _token Address of the ERC20 token to decrease allowance for
     * @param _spender Address of the spender of the tokens
     * @param _amount Amount of tokens to decrease allowance by
     */
    function decreaseERC20Allowance(
        IERC20 _token,
        address _spender,
        uint256 _amount
    ) external onlyManagerOrOwner {
        _token.safeDecreaseAllowance(_spender, _amount);
    }

    /**
     * @notice Increase allowance of ERC20 tokens held by this contract.
     * @dev Only callable by the owner or asset manager.
     * @dev Allowance can only be increased for approved `spender` addresses.
     * @dev Current allowance should be computed off-chain to avoid any overflow.
     * @param _token Address of the ERC20 token to increase allowance for
     * @param _spender Address of the spender of the tokens
     * @param _amount Amount of tokens to increase allowance by
     */
    function increaseERC20Allowance(
        IERC20 _token,
        address _spender,
        uint256 _amount
    ) external onlyManagerOrOwner {
        require(approved[_spender], "TVault/spender-not-approved");
        _token.safeIncreaseAllowance(_spender, _amount);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
  * @title TokenFaucet
  * @notice Allow users to claim tokens that were deposited in this contract.
  */
contract TokenFaucet {
  using SafeERC20 for IERC20;

  /**
    * @notice Drips some tokens to caller.
    * @dev We send 0.01% of our tokens to the caller. Over time, the amount will tend toward and eventually reach zero.
    * @param _token Address of the token to drip
    */
  function drip(IERC20 _token) public {
      uint256 _balance = _token.balanceOf(address(this));
      require(_balance > 0, "TokenFaucet/empty-token-balance");
      _token.safeTransfer(msg.sender, _balance / 10000); // 0.01%
  }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@pooltogether/owner-manager-contracts/contracts/Manageable.sol";

import "./interfaces/IDrawCalculatorV3.sol";

/**
    * @title  PoolTogether V4 PrizeDistributorV2
    * @author PoolTogether Inc Team
    * @notice The PrizeDistributorV2 contract holds Tickets (captured interest) and distributes tickets to users with winning draw claims.
              PrizeDistributorV2 uses an external IDrawCalculatorV3 to validate a users draw claim, before awarding payouts. To prevent users
              from reclaiming prizes, a payout history for each draw claim is mapped to user accounts. Reclaiming a draw can occur
              if an "optimal" prize was not included in previous claim pick indices and the new claims updated payout is greater then
              the previous prize distributor claim payout.
*/
contract PrizeDistributorV2 is Manageable {
    using SafeERC20 for IERC20;

    /**
     * @notice Emitted when user has claimed token from the PrizeDistributorV2.
     * @param user   User address receiving draw claim payouts
     * @param drawId Draw id that was paid out
     * @param payout Payout for draw
     * @param pickIndices Pick indices for draw
     */
    event ClaimedDraw(
        address indexed user,
        uint32 indexed drawId,
        uint256 payout,
        uint64[] pickIndices
    );

    /**
     * @notice Emitted when IDrawCalculatorV3 is set.
     * @param caller Address who has set the new DrawCalculator
     * @param calculator IDrawCalculatorV3 address
     */
    event DrawCalculatorSet(address indexed caller, IDrawCalculatorV3 indexed calculator);

    /**
     * @notice Emitted when Token is set.
     * @param token Token address
     */
    event TokenSet(IERC20 indexed token);

    /**
     * @notice Emitted when tokenVault is set.
     * @param caller Address who has set the new tokenVault
     * @param tokenVault Address of the tokenVault that was set
     */
    event TokenVaultSet(address indexed caller, address indexed tokenVault);

    /**
     * @notice Emitted when ERC20 tokens are withdrawn.
     * @param token  ERC20 token transferred
     * @param to     Address that received funds
     * @param amount Amount of tokens transferred
     */
    event ERC20Withdrawn(IERC20 indexed token, address indexed to, uint256 amount);

    /* ============ Global Variables ============ */

    /// @notice IDrawCalculatorV3 address
    IDrawCalculatorV3 internal drawCalculator;

    /// @notice Token address
    IERC20 internal immutable token;

    /// @notice The tokenVault that stores the prize tokens
    address internal tokenVault;

    /// @notice Maps users => drawId => paid out balance
    mapping(address => mapping(uint256 => uint256)) internal userDrawPayouts;

    /* ============ Constructor ============ */

    /**
     * @notice Constructs PrizeDistributorV2 smart contract.
     * @param _owner Contract owner address
     * @param _token Address of the token being used to pay out prizes
     * @param _drawCalculator Address of the DrawCalculatorV3 contract which computes draw payouts
     * @param _tokenVault Address of the TokenVault contract that holds the `token` being used to pay out prizes
     */
    constructor(
        address _owner,
        IERC20 _token,
        IDrawCalculatorV3 _drawCalculator,
        address _tokenVault
    ) Ownable(_owner) {
        require(_owner != address(0), "PDistV2/owner-not-zero-address");
        require(address(_token) != address(0), "PDistV2/token-not-zero-address");

        _setDrawCalculator(_drawCalculator);
        _setTokenVault(_tokenVault);

        token = _token;

        emit TokenSet(_token);
    }

    /* ============ External Functions ============ */

    /**
     * @notice Claim prize payout(s) by submitting valid drawId(s) and winning pick indice(s). The user address
               is used as the "seed" phrase to generate random numbers.
     * @dev    The claim function is public and any wallet may execute claim on behalf of another user.
               Prizes are always paid out to the designated user account and not the caller (msg.sender).
               Claiming prizes is not limited to a single transaction. Reclaiming can be executed
               subsequentially if an "optimal" prize was not included in previous claim pick indices. The
               payout difference for the new claim is calculated during the award process and transfered to user.
     * @param _ticket Address of the Ticket to claim prizes for
     * @param _user Address of the user to claim rewards for. Does NOT need to be msg.sender
     * @param _drawIds Draw IDs from global DrawBuffer reference
     * @param _drawPickIndices Pick indices for each drawId
     * @return Total claim payout. May include calculations from multiple draws.
     */
    function claim(
        ITicket _ticket,
        address _user,
        uint32[] calldata _drawIds,
        uint64[][] calldata _drawPickIndices
    ) external returns (uint256) {
        uint256 totalPayout;

        (uint256[] memory drawPayouts, ) = drawCalculator.calculate(
            _ticket,
            _user,
            _drawIds,
            _drawPickIndices
        );

        uint256 drawPayoutsLength = drawPayouts.length;

        for (uint256 payoutIndex = 0; payoutIndex < drawPayoutsLength; payoutIndex++) {
            uint32 drawId = _drawIds[payoutIndex];
            uint256 payout = drawPayouts[payoutIndex];
            uint256 oldPayout = _getDrawPayoutBalanceOf(_user, drawId);
            uint256 payoutDiff = 0;

            // helpfully short-circuit, in case the user screwed something up.
            require(payout > oldPayout, "PDistV2/zero-payout");

            unchecked {
                payoutDiff = payout - oldPayout;
            }

            _setDrawPayoutBalanceOf(_user, drawId, payout);

            totalPayout += payoutDiff;

            emit ClaimedDraw(_user, drawId, payoutDiff, _drawPickIndices[payoutIndex]);
        }

        _awardPayout(_user, totalPayout);

        return totalPayout;
    }

    /**
     * @notice Transfer ERC20 tokens out of contract to recipient address.
     * @dev Only callable by contract owner or manager.
     * @param _erc20Token Address of the ERC20 token to transfer
     * @param _to Address of the recipient of the tokens
     * @param _amount Amount of tokens to transfer
     * @return true if operation is successful.
     */
    function withdrawERC20(
        IERC20 _erc20Token,
        address _to,
        uint256 _amount
    ) external onlyManagerOrOwner returns (bool) {
        require(_to != address(0), "PDistV2/to-not-zero-address");
        require(address(_erc20Token) != address(0), "PDistV2/ERC20-not-zero-address");

        _erc20Token.safeTransfer(_to, _amount);

        emit ERC20Withdrawn(_erc20Token, _to, _amount);

        return true;
    }

    /**
     * @notice Read global DrawCalculator address.
     * @return IDrawCalculatorV3
     */
    function getDrawCalculator() external view returns (IDrawCalculatorV3) {
        return drawCalculator;
    }

    /**
     * @notice Get the amount that a user has already been paid out for a draw
     * @param _user User address
     * @param _drawId Draw ID
     */
    function getDrawPayoutBalanceOf(address _user, uint32 _drawId) external view returns (uint256) {
        return _getDrawPayoutBalanceOf(_user, _drawId);
    }

    /**
     * @notice Read global Token address.
     * @return IERC20
     */
    function getToken() external view returns (IERC20) {
        return token;
    }

    /**
     * @notice Read global tokenVault address.
     * @return Address of the tokenVault
     */
    function getTokenVault() external view returns (address) {
        return tokenVault;
    }

    /**
     * @notice Sets DrawCalculator reference contract.
     * @param _newCalculator DrawCalculator address
     * @return New DrawCalculator address
     */
    function setDrawCalculator(IDrawCalculatorV3 _newCalculator)
        external
        onlyManagerOrOwner
        returns (IDrawCalculatorV3)
    {
        _setDrawCalculator(_newCalculator);
        return _newCalculator;
    }

    /**
     * @notice Sets TokenVault address.
     * @param _tokenVault Address of the new TokenVault
     * @return New TokenVault address
     */
    function setTokenVault(address _tokenVault) external onlyManagerOrOwner returns (address) {
        _setTokenVault(_tokenVault);
        return _tokenVault;
    }

    /* ============ Internal Functions ============ */

    /**
     * @notice Get payout balance of a user for a draw ID.
     * @param _user Address of the user to get payout balance for
     * @param _drawId Draw ID to get payout balance for
     * @return Draw ID payout balance
     */
    function _getDrawPayoutBalanceOf(address _user, uint32 _drawId)
        internal
        view
        returns (uint256)
    {
        return userDrawPayouts[_user][_drawId];
    }

    /**
     * @notice Set payout balance for a user and draw ID.
     * @param _user Address of the user to set payout balance for
     * @param _drawId Draw ID to set payout balance for
     * @param _payout Payout amount to set
     */
    function _setDrawPayoutBalanceOf(
        address _user,
        uint32 _drawId,
        uint256 _payout
    ) internal {
        userDrawPayouts[_user][_drawId] = _payout;
    }

    /**
     * @notice Sets IDrawCalculatorV3 reference for individual draw id.
     * @param _newCalculator  IDrawCalculatorV3 address
     */
    function _setDrawCalculator(IDrawCalculatorV3 _newCalculator) internal {
        require(address(_newCalculator) != address(0), "PDistV2/calc-not-zero-address");
        drawCalculator = _newCalculator;

        emit DrawCalculatorSet(msg.sender, _newCalculator);
    }

    /**
     * @notice Sets TokenVault address.
     * @param _tokenVault Address of the new TokenVault
     */
    function _setTokenVault(address _tokenVault) internal {
        require(_tokenVault != address(0), "PDistV2/vault-not-zero-address");
        tokenVault = _tokenVault;

        emit TokenVaultSet(msg.sender, _tokenVault);
    }

    /**
     * @notice Transfer claimed draw(s) total payout to user.
     * @param _to Address of the user to award payout to
     * @param _amount Amount of `token` to transfer
     */
    function _awardPayout(address _to, uint256 _amount) internal {
        token.safeTransferFrom(tokenVault, _to, _amount);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "./ITicket.sol";
import "./IDrawBuffer.sol";
import "./IGaugeController.sol";
import "./IPrizeConfigHistory.sol";

/**
 * @title  PoolTogether V4 IDrawCalculatorV3
 * @author PoolTogether Inc Team
 * @notice The DrawCalculator interface.
 */
interface IDrawCalculatorV3 {
    /**
     * @notice Calculates the awardable prizes for a user for Multiple Draws. Typically called by a PrizeDistributor.
     * @param ticket Address of the ticket to calculate awardable prizes for
     * @param user Address of the user for which to calculate awardable prizes for
     * @param drawIds Array of DrawIds for which to calculate awardable prizes for
     * @param drawPickIndices Pick indices for each drawId
     * @return List of awardable prize amounts ordered by drawId.
     * @return List of prize counts ordered by tiers.
     */
    function calculate(
        ITicket ticket,
        address user,
        uint32[] calldata drawIds,
        uint64 [][] calldata drawPickIndices
    )
        external
        view
        returns (
            uint256[] memory,
            bytes memory
        );

    /**
     * @notice Calculates picks for a user for Multiple Draws.
     * @param ticket Address of the ticket to calculate picks for
     * @param user Address of the user for which to calculate picks for
     * @param drawIds Array of DrawIds for which to calculate picks for
     */
    function calculateUserPicks(
        ITicket ticket,
        address user,
        uint32[] calldata drawIds
    ) external view returns (uint64[] memory);

    /**
     * @notice Returns DrawBuffer address.
     * @return The DrawBuffer address
     */
    function getDrawBuffer() external view returns (IDrawBuffer);

    /**
     * @notice Returns GaugeController address.
     * @return The GaugeController address
     */
    function getGaugeController() external view returns (IGaugeController);

    /**
     * @notice Returns PrizeConfigHistory address.
     * @return The PrizeConfigHistory address
     */
    function getPrizeConfigHistory() external view returns (IPrizeConfigHistory);

    /**
     * @notice Returns the total number of picks for a prize pool / ticket.
     * @param ticket Address of the ticket to get total picks for
     * @param startTime Timestamp at which the draw starts
     * @param endTime Timestamp at which the draw ends
     * @param poolStakeCeiling Globally configured pool stake ceiling
     * @param bitRange Number of bits allocated to each division
     * @param cardinality Number of sub-divisions of a random number
     * @return Total number of picks for this prize pool / ticket
     */
    function getTotalPicks(
        ITicket ticket,
        uint256 startTime,
        uint256 endTime,
        uint256 poolStakeCeiling,
        uint8 bitRange,
        uint8 cardinality
    ) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "../interfaces/IDrawBeacon.sol";

/** @title  IDrawBuffer
  * @author PoolTogether Inc Team
  * @notice The DrawBuffer interface.
*/
interface IDrawBuffer {
    /**
     * @notice Emit when a new draw has been created.
     * @param drawId Draw id
     * @param draw The Draw struct
     */
    event DrawSet(uint32 indexed drawId, IDrawBeacon.Draw draw);

    /**
     * @notice Read a ring buffer cardinality
     * @return Ring buffer cardinality
     */
    function getBufferCardinality() external view returns (uint32);

    /**
     * @notice Read a Draw from the draws ring buffer.
     * @dev    Read a Draw using the Draw.drawId to calculate position in the draws ring buffer.
     * @param drawId Draw.drawId
     * @return IDrawBeacon.Draw
     */
    function getDraw(uint32 drawId) external view returns (IDrawBeacon.Draw memory);

    /**
     * @notice Read multiple Draws from the draws ring buffer.
     * @dev    Read multiple Draws using each drawId to calculate position in the draws ring buffer.
     * @param drawIds Array of drawIds
     * @return IDrawBeacon.Draw[]
     */
    function getDraws(uint32[] calldata drawIds) external view returns (IDrawBeacon.Draw[] memory);

    /**
     * @notice Gets the number of Draws held in the draw ring buffer.
     * @dev If no Draws have been pushed, it will return 0.
     * @dev If the ring buffer is full, it will return the cardinality.
     * @dev Otherwise, it will return the NewestDraw index + 1.
     * @return Number of Draws held in the draw ring buffer.
     */
    function getDrawCount() external view returns (uint32);

    /**
     * @notice Read newest Draw from draws ring buffer.
     * @dev    Uses the nextDrawIndex to calculate the most recently added Draw.
     * @return IDrawBeacon.Draw
     */
    function getNewestDraw() external view returns (IDrawBeacon.Draw memory);

    /**
     * @notice Read oldest Draw from draws ring buffer.
     * @dev    Finds the oldest Draw by comparing and/or diffing totalDraws with the cardinality.
     * @return IDrawBeacon.Draw
     */
    function getOldestDraw() external view returns (IDrawBeacon.Draw memory);

    /**
     * @notice Push Draw onto draws ring buffer history.
     * @dev    Push new draw onto draws history via authorized manager or owner.
     * @param draw IDrawBeacon.Draw
     * @return Draw.drawId
     */
    function pushDraw(IDrawBeacon.Draw calldata draw) external returns (uint32);

    /**
     * @notice Set existing Draw in draws ring buffer with new parameters.
     * @dev    Updating a Draw should be used sparingly and only in the event an incorrect Draw parameter has been stored.
     * @param newDraw IDrawBeacon.Draw
     * @return Draw.drawId
     */
    function setDraw(IDrawBeacon.Draw calldata newDraw) external returns (uint32);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

/**
 * @title  PoolTogether V4 IPrizeConfigHistory
 * @author PoolTogether Inc Team
 * @notice IPrizeConfigHistory is the base contract for PrizeConfigHistory
 */
interface IPrizeConfigHistory {
    /**
     * @notice PrizeConfig struct read every draw.
     * @param bitRangeSize Number of bits in decimal allocated to each division
     * @param matchCardinality Number of numbers to consider in the 256 bit random number. Must be > 1 and < 256/bitRangeSize.
     * @param maxPicksPerUser Maximum number of picks a user can make in this draw
     * @param drawId Draw ID at which the PrizeConfig was pushed and is since valid
     * @param expiryDuration Length of time in seconds the PrizeDistribution is valid for. Relative to the Draw.timestamp.
     * @param endTimestampOffset The end time offset in seconds from which Ticket balances are calculated.
     * @param poolStakeCeiling Total globally configured POOL staking ceiling
     * @param prize Total prize amount available for this draw
     * @param tiers Array of prize tiers percentages, expressed in fraction form with base 1e9. Ordering: index0: grandPrize, index1: runnerUp, etc.
     */
    struct PrizeConfig {
        uint8 bitRangeSize;
        uint8 matchCardinality;
        uint16 maxPicksPerUser;
        uint32 drawId;
        uint32 expiryDuration;
        uint32 endTimestampOffset;
        uint128 poolStakeCeiling;
        uint256 prize;
        uint32[16] tiers;
    }

    /**
     * @notice Returns the number of PrizeConfig structs pushed
     * @return The number of prize config that have been pushed
     */
    function count() external view returns (uint256);

    /**
     * @notice Returns last Draw ID recorded in the history.
     * @return Draw ID of the last PrizeConfig record
     */
    function getNewestDrawId() external view returns (uint32);

    /**
     * @notice Returns first Draw ID used to initialize history.
     * @return Draw ID of the first PrizeConfig record
     */
    function getOldestDrawId() external view returns (uint32);

    /**
     * @notice Returns PrizeConfig struct for the passed Draw ID.
     * @param drawId Draw ID for which to return PrizeConfig struct
     * @return The PrizeConfig struct for the passed Draw ID
     */
    function getPrizeConfig(uint32 drawId) external view returns (PrizeConfig memory);

    /**
     * @notice Returns the PrizeConfig struct at the given index.
     * @param index Index at which the PrizeConfig struct is stored
     * @return The PrizeConfig struct at the given index
     */
    function getPrizeConfigAtIndex(uint256 index) external view returns (PrizeConfig memory);

    /**
     * @notice Returns a list of PrizeConfig from the history array.
     * @param drawIds List of Draw IDs for which to return PrizeConfig structs
     * @return The list of PrizeConfig structs for the passed Draw IDs
     */
    function getPrizeConfigList(uint32[] calldata drawIds)
        external
        view
        returns (PrizeConfig[] memory);

    /**
     * @notice Push PrizeConfigHistory struct onto history array.
     * @dev Callable only by the owner.
     * @param prizeConfig Updated PrizeConfigHistory struct
     * @return Draw ID at which the PrizeConfig was pushed and is since valid
     */
    function popAndPush(PrizeConfig calldata prizeConfig) external returns (uint32);

    /**
     * @notice Push PrizeConfig struct onto history array.
     * @dev Callable only by the owner or manager.
     * @param prizeConfig New PrizeConfig struct to push onto the history array
     */
    function push(PrizeConfig calldata prizeConfig) external;

    /**
     * @notice Replace PrizeConfig struct from history array.
     * @dev Callable only by the owner.
     * @param prizeConfig New PrizeConfig struct that will replace the previous PrizeConfig at the corresponding index
     */
    function replace(PrizeConfig calldata prizeConfig) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@pooltogether/pooltogether-rng-contracts/contracts/RNGInterface.sol";
import "./IDrawBuffer.sol";

/** @title  IDrawBeacon
  * @author PoolTogether Inc Team
  * @notice The DrawBeacon interface.
*/
interface IDrawBeacon {

    /// @notice Draw struct created every draw
    /// @param winningRandomNumber The random number returned from the RNG service
    /// @param drawId The monotonically increasing drawId for each draw
    /// @param timestamp Unix timestamp of the draw. Recorded when the draw is created by the DrawBeacon.
    /// @param beaconPeriodStartedAt Unix timestamp of when the draw started
    /// @param beaconPeriodSeconds Unix timestamp of the beacon draw period for this draw.
    struct Draw {
        uint256 winningRandomNumber;
        uint32 drawId;
        uint64 timestamp;
        uint64 beaconPeriodStartedAt;
        uint32 beaconPeriodSeconds;
    }

    /**
     * @notice Emit when a new DrawBuffer has been set.
     * @param newDrawBuffer       The new DrawBuffer address
     */
    event DrawBufferUpdated(IDrawBuffer indexed newDrawBuffer);

    /**
     * @notice Emit when a draw has opened.
     * @param startedAt Start timestamp
     */
    event BeaconPeriodStarted(uint64 indexed startedAt);

    /**
     * @notice Emit when a draw has started.
     * @param rngRequestId  draw id
     * @param rngLockBlock  Block when draw becomes invalid
     */
    event DrawStarted(uint32 indexed rngRequestId, uint32 rngLockBlock);

    /**
     * @notice Emit when a draw has been cancelled.
     * @param rngRequestId  draw id
     * @param rngLockBlock  Block when draw becomes invalid
     */
    event DrawCancelled(uint32 indexed rngRequestId, uint32 rngLockBlock);

    /**
     * @notice Emit when a draw has been completed.
     * @param randomNumber  Random number generated from draw
     */
    event DrawCompleted(uint256 randomNumber);

    /**
     * @notice Emit when a RNG service address is set.
     * @param rngService  RNG service address
     */
    event RngServiceUpdated(RNGInterface indexed rngService);

    /**
     * @notice Emit when a draw timeout param is set.
     * @param rngTimeout  draw timeout param in seconds
     */
    event RngTimeoutSet(uint32 rngTimeout);

    /**
     * @notice Emit when the drawPeriodSeconds is set.
     * @param drawPeriodSeconds Time between draw
     */
    event BeaconPeriodSecondsUpdated(uint32 drawPeriodSeconds);

    /**
     * @notice Returns the number of seconds remaining until the beacon period can be complete.
     * @return The number of seconds remaining until the beacon period can be complete.
     */
    function beaconPeriodRemainingSeconds() external view returns (uint64);

    /**
     * @notice Returns the timestamp at which the beacon period ends
     * @return The timestamp at which the beacon period ends.
     */
    function beaconPeriodEndAt() external view returns (uint64);

    /**
     * @notice Returns whether a Draw can be started.
     * @return True if a Draw can be started, false otherwise.
     */
    function canStartDraw() external view returns (bool);

    /**
     * @notice Returns whether a Draw can be completed.
     * @return True if a Draw can be completed, false otherwise.
     */
    function canCompleteDraw() external view returns (bool);

    /**
     * @notice Calculates when the next beacon period will start.
     * @param time The timestamp to use as the current time
     * @return The timestamp at which the next beacon period would start
     */
    function calculateNextBeaconPeriodStartTime(uint64 time) external view returns (uint64);

    /**
     * @notice Can be called by anyone to cancel the draw request if the RNG has timed out.
     */
    function cancelDraw() external;

    /**
     * @notice Completes the Draw (RNG) request and pushes a Draw onto DrawBuffer.
     */
    function completeDraw() external;

    /**
     * @notice Returns the block number that the current RNG request has been locked to.
     * @return The block number that the RNG request is locked to
     */
    function getLastRngLockBlock() external view returns (uint32);

    /**
     * @notice Returns the current RNG Request ID.
     * @return The current Request ID
     */
    function getLastRngRequestId() external view returns (uint32);

    /**
     * @notice Returns whether the beacon period is over
     * @return True if the beacon period is over, false otherwise
     */
    function isBeaconPeriodOver() external view returns (bool);

    /**
     * @notice Returns whether the random number request has completed.
     * @return True if a random number request has completed, false otherwise.
     */
    function isRngCompleted() external view returns (bool);

    /**
     * @notice Returns whether a random number has been requested
     * @return True if a random number has been requested, false otherwise.
     */
    function isRngRequested() external view returns (bool);

    /**
     * @notice Returns whether the random number request has timed out.
     * @return True if a random number request has timed out, false otherwise.
     */
    function isRngTimedOut() external view returns (bool);

    /**
     * @notice Allows the owner to set the beacon period in seconds.
     * @param beaconPeriodSeconds The new beacon period in seconds.  Must be greater than zero.
     */
    function setBeaconPeriodSeconds(uint32 beaconPeriodSeconds) external;

    /**
     * @notice Allows the owner to set the RNG request timeout in seconds. This is the time that must elapsed before the RNG request can be cancelled and the pool unlocked.
     * @param rngTimeout The RNG request timeout in seconds.
     */
    function setRngTimeout(uint32 rngTimeout) external;

    /**
     * @notice Sets the RNG service that the Prize Strategy is connected to
     * @param rngService The address of the new RNG service interface
     */
    function setRngService(RNGInterface rngService) external;

    /**
     * @notice Starts the Draw process by starting random number request. The previous beacon period must have ended.
     * @dev The RNG-Request-Fee is expected to be held within this contract before calling this function
     */
    function startDraw() external;

    /**
     * @notice Set global DrawBuffer variable.
     * @dev    All subsequent Draw requests/completions will be pushed to the new DrawBuffer.
     * @param newDrawBuffer DrawBuffer address
     * @return DrawBuffer
     */
    function setDrawBuffer(IDrawBuffer newDrawBuffer) external returns (IDrawBuffer);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0;

/// @title Random Number Generator Interface
/// @notice Provides an interface for requesting random numbers from 3rd-party RNG services (Chainlink VRF, Starkware VDF, etc..)
interface RNGInterface {

  /// @notice Emitted when a new request for a random number has been submitted
  /// @param requestId The indexed ID of the request used to get the results of the RNG service
  /// @param sender The indexed address of the sender of the request
  event RandomNumberRequested(uint32 indexed requestId, address indexed sender);

  /// @notice Emitted when an existing request for a random number has been completed
  /// @param requestId The indexed ID of the request used to get the results of the RNG service
  /// @param randomNumber The random number produced by the 3rd-party service
  event RandomNumberCompleted(uint32 indexed requestId, uint256 randomNumber);

  /// @notice Gets the last request id used by the RNG service
  /// @return requestId The last request id used in the last request
  function getLastRequestId() external view returns (uint32 requestId);

  /// @notice Gets the Fee for making a Request against an RNG service
  /// @return feeToken The address of the token that is used to pay fees
  /// @return requestFee The fee required to be paid to make a request
  function getRequestFee() external view returns (address feeToken, uint256 requestFee);

  /// @notice Sends a request for a random number to the 3rd-party service
  /// @dev Some services will complete the request immediately, others may have a time-delay
  /// @dev Some services require payment in the form of a token, such as $LINK for Chainlink VRF
  /// @return requestId The ID of the request used to get the results of the RNG service
  /// @return lockBlock The block number at which the RNG service will start generating time-delayed randomness.  The calling contract
  /// should "lock" all activity until the result is available via the `requestId`
  function requestRandomNumber() external returns (uint32 requestId, uint32 lockBlock);

  /// @notice Checks if the request for randomness from the 3rd-party service has completed
  /// @dev For time-delayed requests, this function is used to check/confirm completion
  /// @param requestId The ID of the request used to get the results of the RNG service
  /// @return isCompleted True if the request has completed and a random number is available, false otherwise
  function isRequestComplete(uint32 requestId) external view returns (bool isCompleted);

  /// @notice Gets the random number produced by the 3rd-party service
  /// @param requestId The ID of the request used to get the results of the RNG service
  /// @return randomNum The random number
  function randomNumber(uint32 requestId) external returns (uint256 randomNum);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@pooltogether/owner-manager-contracts/contracts/Manageable.sol";
import "@pooltogether/v4-periphery/contracts/libraries/BinarySearchLib.sol";

import "./interfaces/IPrizeConfigHistory.sol";

/**
 * @title  PoolTogether V4 PrizeConfigHistory
 * @author PoolTogether Inc Team
 * @notice Contract to store prize configurations
 */
contract PrizeConfigHistory is IPrizeConfigHistory, Manageable {
    /// @dev The uint32[] type is extended with a binarySearch(uint32) function.
    using BinarySearchLib for uint32[];

    /* ============ Variables ============ */

    /**
     * @notice Ordered array of Draw IDs.
     * @dev The history, with sequentially ordered ids, can be searched using binary search.
            The binary search will find index of a drawId (atOrBefore) using a specific drawId (at).
            When a new Draw ID is added to the history, a corresponding mapping of the ID is
            updated in the prizeConfigs mapping.
    */
    uint32[] internal history;

    /**
     * @notice Mapping of Draw ID to PrizeConfig struct.
     * @dev drawId -> PrizeConfig
     * @dev The prizeConfigs mapping is updated when a new Draw ID is added to the history.
     */
    mapping(uint32 => PrizeConfig) internal prizeConfigs;

    /* ============ Events ============ */

    /**
     * @notice Emit when a new PrizeConfig is added to history
     * @param drawId    Draw ID at which the PrizeConfig was pushed and is since valid
     * @param prizeConfig PrizeConfig struct
     */
    event PrizeConfigPushed(uint32 indexed drawId, PrizeConfig prizeConfig);

    /**
     * @notice Emit when existing PrizeConfig is updated in history
     * @param drawId    Draw ID at which the PrizeConfig was set and is since valid
     * @param prizeConfig PrizeConfig struct
     */
    event PrizeConfigSet(uint32 indexed drawId, PrizeConfig prizeConfig);

    /* ============ Constructor ============ */

    /**
     * @notice PrizeConfigHistory constructor
     * @param _owner Address of the owner
     */
    constructor(address _owner) Ownable(_owner) {}

    /* ============ External Functions ============ */

    /// @inheritdoc IPrizeConfigHistory
    function count() external view override returns (uint256) {
        return history.length;
    }

    /// @inheritdoc IPrizeConfigHistory
    function getNewestDrawId() external view override returns (uint32) {
        return history[history.length - 1];
    }

    /// @inheritdoc IPrizeConfigHistory
    function getOldestDrawId() external view override returns (uint32) {
        return history[0];
    }

    /// @inheritdoc IPrizeConfigHistory
    function getPrizeConfig(uint32 _drawId)
        external
        view
        override
        returns (PrizeConfig memory prizeConfig)
    {
        require(_drawId > 0, "PrizeConfHistory/draw-id-gt-zero");
        return prizeConfigs[history.binarySearch(_drawId)];
    }

    /// @inheritdoc IPrizeConfigHistory
    function getPrizeConfigAtIndex(uint256 _index)
        external
        view
        override
        returns (PrizeConfig memory prizeConfig)
    {
        return prizeConfigs[uint32(_index)];
    }

    // @inheritdoc IPrizeConfigHistory
    function getPrizeConfigList(uint32[] calldata _drawIds)
        external
        view
        override
        returns (PrizeConfig[] memory prizeConfigList)
    {
        uint256 _length = _drawIds.length;
        PrizeConfig[] memory _data = new PrizeConfig[](_length);

        for (uint256 index = 0; index < _length; index++) {
            _data[index] = prizeConfigs[history.binarySearch(_drawIds[index])];
        }

        return _data;
    }

    /// @inheritdoc IPrizeConfigHistory
    function popAndPush(PrizeConfig calldata _newPrizeConfig)
        external
        override
        onlyOwner
        returns (uint32)
    {
        uint256 length = history.length;

        require(length > 0, "PrizeConfHistory/history-empty");
        require(history[length - 1] == _newPrizeConfig.drawId, "PrizeConfHistory/invalid-draw-id");

        _replace(_newPrizeConfig);

        return _newPrizeConfig.drawId;
    }

    /// @inheritdoc IPrizeConfigHistory
    function push(PrizeConfig calldata _nextPrizeConfig) external override onlyManagerOrOwner {
        _push(_nextPrizeConfig);
    }

    /// @inheritdoc IPrizeConfigHistory
    function replace(PrizeConfig calldata _newPrizeConfig) external override onlyOwner {
        _replace(_newPrizeConfig);
    }

    /* ============ Internal Functions ============ */

    /**
     * @notice Push PrizeConfigHistory struct onto history array.
     * @param _prizeConfig New PrizeConfig struct to push onto history array
     */
    function _push(PrizeConfig memory _prizeConfig) internal {
        uint256 _historyLength = history.length;

        if (_historyLength > 0) {
            uint256 _id = history[uint32(_historyLength - 1)];

            require(_prizeConfig.drawId > uint32(_id), "PrizeConfHistory/nonsequentialId");
        }

        history.push(_prizeConfig.drawId);
        prizeConfigs[uint32(_historyLength)] = _prizeConfig;

        emit PrizeConfigPushed(_prizeConfig.drawId, _prizeConfig);
    }

    /**
     * @notice Replace PrizeConfig struct from history array.
     * @dev Performs a binary search to find which index in the history array contains the drawId to replace.
     * @param _prizeConfig New PrizeConfig struct that will replace the previous PrizeConfig at the corresponding index.
     */
    function _replace(PrizeConfig calldata _prizeConfig) internal {
        require(history.length > 0, "PrizeConfHistory/no-prize-conf");

        uint32 oldestDrawId = history[0];
        require(_prizeConfig.drawId >= oldestDrawId, "PrizeConfHistory/drawId-beyond");

        uint32 index = history.binarySearch(_prizeConfig.drawId);
        require(history[index] == _prizeConfig.drawId, "PrizeConfHistory/drawId-mismatch");

        prizeConfigs[index] = _prizeConfig;
        emit PrizeConfigSet(_prizeConfig.drawId, _prizeConfig);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;

/**
 * @title  PoolTogether V4 BinarySearchLib
 * @author PoolTogether Inc Team
 * @notice BinarySearchLib uses binary search to find a parent contract struct with the drawId parameter
 * @dev    The implementing contract must provider access to a struct (i.e. PrizeTier) list with is both
 *         sorted and indexed by the drawId field for binary search to work.
 */
library BinarySearchLib {

    /**
     * @notice Find ID in array of ordered IDs using Binary Search.
        * @param _history uin32[] - Array of IDsq
        * @param _drawId uint32 - Draw ID to search for
        * @return uint32 - Index of ID in array
     */
    function binarySearch(uint32[] storage _history, uint32 _drawId) internal view returns (uint32) {
        uint32 index;
        uint32 leftSide = 0;
        uint32 rightSide = uint32(_history.length - 1);

        uint32 oldestDrawId = _history[0];
        uint32 newestDrawId = _history[rightSide];

        require(_drawId >= oldestDrawId, "BinarySearchLib/draw-id-out-of-range");
        if (_drawId >= newestDrawId) return rightSide;
        if (_drawId == oldestDrawId) return leftSide;

        while (true) {
            uint32 length = rightSide - leftSide;
            uint32 center = leftSide + (length / 2);
            uint32 centerID = _history[center];

            if (centerID == _drawId) {
                index = center;
                break;
            }

            if (length <= 1) {
                if(_history[rightSide] <= _drawId) {
                    index = rightSide;
                } else {
                    index = leftSide;
                }
                break;
            }
            
            if (centerID < _drawId) {
                leftSide = center;
            } else {
                rightSide = center - 1;
            }
        }

        return index;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@pooltogether/owner-manager-contracts/contracts/Manageable.sol";

import "./interfaces/IDrawBuffer.sol";
import "./interfaces/IDrawCalculatorV3.sol";
import "./interfaces/IGaugeController.sol";
import "./interfaces/IPrizeConfigHistory.sol";

import "./PrizeDistributor.sol";
import "./PrizeConfigHistory.sol";

/**
  * @title  PoolTogether V4 DrawCalculatorV3
  * @author PoolTogether Inc Team
  * @notice The DrawCalculator calculates a user's prize by matching a winning random number against
            their picks. A users picks are generated deterministically based on their address and balance
            of tickets held. Prize payouts are divided into multiple tiers: grand prize, second place, etc...
            A user with a higher average weighted balance (during each draw period) will be given a large number of
            picks to choose from, and thus a higher chance to match the winning numbers.
*/
contract DrawCalculatorV3 is IDrawCalculatorV3, Manageable {
    /// @dev The uint32[] type is extended with a binarySearch(uint32) function.
    using BinarySearchLib for uint32[];

    /* ============ Variables ============ */

    /// @notice DrawBuffer address
    IDrawBuffer internal immutable drawBuffer;

    /// @notice GaugeController address
    IGaugeController internal immutable gaugeController;

    /// @notice PrizeConfigHistory address
    IPrizeConfigHistory internal immutable prizeConfigHistory;

    /// @notice The tiers array length
    uint8 public constant TIERS_LENGTH = 16;

    /* ============ Events ============ */

    /**
    * @notice Emitted when the contract is initialized
    * @param gaugeController Address of the GaugeController
    * @param drawBuffer Address of the DrawBuffer
    * @param prizeConfigHistory Address of the PrizeConfigHistory
    */
    event Deployed(
        IGaugeController indexed gaugeController,
        IDrawBuffer indexed drawBuffer,
        IPrizeConfigHistory indexed prizeConfigHistory
    );

    /* ============ Constructor ============ */

    /**
     * @notice DrawCalculator constructor
     * @param _gaugeController Address of the GaugeController
     * @param _drawBuffer Address of the DrawBuffer to push draws to
     * @param _prizeConfigHistory Address of the PrizeConfigHistory
     * @param _owner Address of the owner
     */
    constructor(
        IGaugeController _gaugeController,
        IDrawBuffer _drawBuffer,
        IPrizeConfigHistory _prizeConfigHistory,
        address _owner
    ) Ownable(_owner) {
        require(address(_gaugeController) != address(0), "DrawCalc/GC-not-zero-address");
        require(address(_drawBuffer) != address(0), "DrawCalc/DB-not-zero-address");
        require(address(_prizeConfigHistory) != address(0), "DrawCalc/PCH-not-zero-address");
        require(_owner != address(0), "DrawCalc/owner-not-zero-address");

        gaugeController = _gaugeController;
        drawBuffer = _drawBuffer;
        prizeConfigHistory = _prizeConfigHistory;

        emit Deployed(_gaugeController, _drawBuffer, _prizeConfigHistory);
    }

    /* ============ External Functions ============ */

    /// @inheritdoc IDrawCalculatorV3
    function calculate(
        ITicket _ticket,
        address _user,
        uint32[] calldata _drawIds,
        uint64 [][] calldata _drawPickIndices
    ) external view override returns (
        uint256[] memory prizesAwardable,
        bytes memory prizeCounts
    ) {
        require(_drawPickIndices.length == _drawIds.length, "DrawCalc/invalid-pick-indices");

        // User address is hashed once.
        bytes32 _userRandomNumber = keccak256(abi.encodePacked(_user));

        (prizesAwardable, prizeCounts) = _calculatePrizesAwardable(
            _ticket,
            _user,
            _userRandomNumber,
            _drawIds,
            _drawPickIndices
        );
    }

    /// @inheritdoc IDrawCalculatorV3
    function calculateUserPicks(
        ITicket _ticket,
        address _user,
        uint32[] calldata _drawIds
    ) external view override returns (uint64[] memory picks) {
        IDrawBeacon.Draw[] memory _draws = drawBuffer.getDraws(_drawIds);
        uint256 _drawsLength = _draws.length;
        picks = new uint64[](_drawIds.length);

        for (uint32 _drawIndex = 0; _drawIndex < _drawsLength; _drawIndex++) {
            IDrawBeacon.Draw memory _draw = _draws[_drawIndex];
            IPrizeConfigHistory.PrizeConfig memory _prizeConfig = prizeConfigHistory.getPrizeConfig(_draw.drawId);

            _requireDrawUnexpired(_draw, _prizeConfig);

            picks[_drawIndex] = _calculateUserPicks(
                _ticket,
                _user,
                _draw.timestamp - _draw.beaconPeriodSeconds,
                _draw.timestamp - _prizeConfig.endTimestampOffset,
                _prizeConfig.poolStakeCeiling,
                _prizeConfig.bitRangeSize,
                _prizeConfig.matchCardinality
            );
        }

        return picks;
    }

    /// @inheritdoc IDrawCalculatorV3
    function getDrawBuffer() external override view returns (IDrawBuffer) {
        return drawBuffer;
    }

    /// @inheritdoc IDrawCalculatorV3
    function getGaugeController() external override view returns (IGaugeController) {
        return gaugeController;
    }

    /// @inheritdoc IDrawCalculatorV3
    function getPrizeConfigHistory() external override view returns (IPrizeConfigHistory) {
        return prizeConfigHistory;
    }

    /// @inheritdoc IDrawCalculatorV3
    function getTotalPicks(
        ITicket _ticket,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _poolStakeCeiling,
        uint8 _bitRange,
        uint8 _cardinality
    ) external override view returns (uint256) {
        return _getTotalPicks(_ticket, _startTime, _endTime, _poolStakeCeiling, _bitRange, _cardinality);
    }

    /* ============ Internal Functions ============ */

    /**
     * @notice Ensure that the draw is not expired.
     * @param _draw Draw
     * @param _prizeConfig PrizeConfig
     */
    function _requireDrawUnexpired(
        IDrawBeacon.Draw memory _draw,
        IPrizeConfigHistory.PrizeConfig memory _prizeConfig
    ) internal view {
        require(uint64(block.timestamp) < _draw.timestamp + _prizeConfig.expiryDuration, "DrawCalc/draw-expired");
    }

    /**
     * @notice Calculates the prizes awardable for each DrawIds passed.
     * @param _ticket Address of the ticket to calculate awardable prizes for
     * @param _user Address of the user for which to calculate awardable prizes for
     * @param _userRandomNumber Random number of the user to consider over draws
     * @param _drawIds Array of DrawIds for which to calculate awardable prizes for
     * @param _drawPickIndices Pick indices for each Draw
     */
    function _calculatePrizesAwardable(
        ITicket _ticket,
        address _user,
        bytes32 _userRandomNumber,
        uint32[] memory _drawIds,
        uint64[][] memory _drawPickIndices
    ) internal view returns (
        uint256[] memory prizesAwardable,
        bytes memory prizeCounts
    ) {
        // READ list of IDrawBeacon.Draw using the drawIds from drawBuffer
        IDrawBeacon.Draw[] memory _draws = drawBuffer.getDraws(_drawIds);
        uint256 _drawsLength = _draws.length;

        uint256[] memory _prizesAwardable = new uint256[](_drawIds.length);
        uint256[][] memory _prizeCounts = new uint256[][](_drawIds.length);

        // Calculate prizes awardable for each Draw passed
        for (uint32 _drawIndex = 0; _drawIndex < _drawsLength; _drawIndex++) {
            IDrawBeacon.Draw memory _draw = _draws[_drawIndex];
            IPrizeConfigHistory.PrizeConfig memory _prizeConfig = prizeConfigHistory.getPrizeConfig(_draw.drawId);

            _requireDrawUnexpired(_draw, _prizeConfig);

            uint64 _totalUserPicks = _calculateUserPicks(
                _ticket,
                _user,
                _draw.timestamp - _draw.beaconPeriodSeconds,
                _draw.timestamp - _prizeConfig.endTimestampOffset,
                _prizeConfig.poolStakeCeiling,
                _prizeConfig.bitRangeSize,
                _prizeConfig.matchCardinality
            );

            (_prizesAwardable[_drawIndex], _prizeCounts[_drawIndex]) = _calculate(
                _draw.winningRandomNumber,
                _totalUserPicks,
                _userRandomNumber,
                _drawPickIndices[_drawIndex],
                _prizeConfig
            );
        }

        prizeCounts = abi.encode(_prizeCounts);
        prizesAwardable = _prizesAwardable;
    }

    /**
     * @notice Calculates the number of picks a user gets for a Draw, considering the normalized user balance and the PrizeConfig.
     * @dev Divided by 1e18 since the normalized user balance is stored as a fixed point 18 number.
     * @param _ticket Address of the ticket to get total picks for
     * @param _startTimestamp Timestamp at which the prize starts
     * @param _endTimestamp Timestamp at which the prize ends
     * @param _poolStakeCeiling Globally configured pool stake ceiling
     * @param _bitRange Number of bits allocated to each division
     * @param _cardinality Number of sub-divisions of a random number
     * @return Number of picks a user gets for a Draw
     */
    function _calculateUserPicks(
        ITicket _ticket,
        address _user,
        uint64 _startTimestamp,
        uint64 _endTimestamp,
        uint256 _poolStakeCeiling,
        uint8 _bitRange,
        uint8 _cardinality
    ) internal view returns (uint64) {
        uint256 _numberOfPicks = _getTotalPicks(_ticket, _startTimestamp, _endTimestamp, _poolStakeCeiling, _bitRange, _cardinality);
        uint256 _normalizedBalance = _getNormalizedBalanceAt(_ticket, _user, _startTimestamp, _endTimestamp);
        return uint64((_normalizedBalance * _numberOfPicks) / 1 ether);
    }

    /**
     * @notice Calculates the normalized balance of a user against the total supply for a draw.
     * @param _ticket Address of the ticket to get normalized balance for
     * @param _user The user to consider
     * @param _startTimestamp Timestamp at which the draw starts
     * @param _endTimestamp Timestamp at which the draw ends
     * @return User normalized balance for the draw
     */
    function _getNormalizedBalanceAt(
        ITicket _ticket,
        address _user,
        uint64 _startTimestamp,
        uint64 _endTimestamp
    ) internal view returns (uint256) {
        uint64[] memory _timestampsWithStartCutoffTimes = new uint64[](1);
        uint64[] memory _timestampsWithEndCutoffTimes = new uint64[](1);

        _timestampsWithStartCutoffTimes[0] = _startTimestamp;
        _timestampsWithEndCutoffTimes[0] = _endTimestamp;

        uint256[] memory _balances = _ticket.getAverageBalancesBetween(
            _user,
            _timestampsWithStartCutoffTimes,
            _timestampsWithEndCutoffTimes
        );

        uint256[] memory _totalSupplies = _ticket.getAverageTotalSuppliesBetween(
            _timestampsWithStartCutoffTimes,
            _timestampsWithEndCutoffTimes
        );

        uint256 _normalizedBalance;

        if (_totalSupplies[0] > 0) {
            _normalizedBalance = (_balances[0] * 1 ether) / _totalSupplies[0];
        }

        return _normalizedBalance;
    }

    /**
    * @notice Returns the total number of picks for a prize pool.
    * @param _ticket Address of the ticket to get total picks for
    * @param _startTime Timestamp at which the prize starts
    * @param _endTime Timestamp at which the prize ends
    * @param _poolStakeCeiling Globally configured pool stake ceiling
    * @param _bitRange Number of bits allocated to each division
    * @param _cardinality Number of sub-divisions of a random number
    * @return Total number of picks for a prize pool
    */
    function _getTotalPicks(
        ITicket _ticket,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _poolStakeCeiling,
        uint8 _bitRange,
        uint8 _cardinality
    ) internal view returns (uint256) {
        uint256 _totalChances = (2**_bitRange)**_cardinality;
        uint256 _gaugeScaledAverage = gaugeController.getScaledAverageGaugeBalanceBetween(address(_ticket), _startTime, _endTime);
        return (_gaugeScaledAverage * _totalChances) / _poolStakeCeiling;
    }

    /**
     * @notice Calculates the prize amount for a PrizeConfig over given picks
     * @param _winningRandomNumber  Draw's winningRandomNumber
     * @param _totalUserPicks       Number of picks the user gets for the Draw
     * @param _userRandomNumber     User randomNumber for that draw
     * @param _picks                User picks for that draw
     * @param _prizeConfig          PrizeConfig for that draw
     * @return prize (if any), prizeCounts (if any)
     */
    function _calculate(
        uint256 _winningRandomNumber,
        uint256 _totalUserPicks,
        bytes32 _userRandomNumber,
        uint64[] memory _picks,
        IPrizeConfigHistory.PrizeConfig memory _prizeConfig
    ) internal pure returns (uint256 prize, uint256[] memory prizeCounts) {
        // Create bitmasks for the PrizeConfig
        uint256[] memory masks = _createBitMasks(_prizeConfig.matchCardinality, _prizeConfig.bitRangeSize);
        uint32 picksLength = uint32(_picks.length);
        uint256[] memory _prizeCounts = new uint256[](_prizeConfig.tiers.length);

        uint8 maxWinningTierIndex = 0;

        require(
            picksLength <= _prizeConfig.maxPicksPerUser,
            "DrawCalc/exceeds-max-user-picks"
        );

        // for each pick, find number of matching numbers and calculate prize configs index
        for (uint32 index = 0; index < picksLength; index++) {
            require(_picks[index] < _totalUserPicks, "DrawCalc/insufficient-user-picks");

            if (index > 0) {
                require(_picks[index] > _picks[index - 1], "DrawCalc/picks-ascending");
            }

            // hash the user random number with the pick value
            uint256 randomNumberThisPick = uint256(
                keccak256(abi.encode(_userRandomNumber, _picks[index]))
            );

            uint8 tiersIndex = _calculateTierIndex(
                randomNumberThisPick,
                _winningRandomNumber,
                masks
            );

            // there is prize for this tier index
            if (tiersIndex < TIERS_LENGTH) {
                if (tiersIndex > maxWinningTierIndex) {
                    maxWinningTierIndex = tiersIndex;
                }
                _prizeCounts[tiersIndex]++;
            }
        }

        // now calculate prizeFraction given prizeCounts
        uint256 prizeFraction = 0;
        uint256[] memory prizeTiersFractions = new uint256[](
            maxWinningTierIndex + 1
        );

        for (uint8 i = 0; i <= maxWinningTierIndex; i++) {
            prizeTiersFractions[i] = _calculatePrizeTierFraction(
                _prizeConfig.tiers[i],
                _prizeConfig.bitRangeSize,
                i
            );
        }

        // multiple the fractions by the prizeCounts and add them up
        for (
            uint256 prizeCountIndex = 0;
            prizeCountIndex <= maxWinningTierIndex;
            prizeCountIndex++
        ) {
            if (_prizeCounts[prizeCountIndex] > 0) {
                prizeFraction +=
                    prizeTiersFractions[prizeCountIndex] *
                    _prizeCounts[prizeCountIndex];
            }
        }

        // return the absolute amount of prize awardable
        // div by 1e9 as prize tiers are base 1e9
        prize = (prizeFraction * _prizeConfig.prize) / 1e9;
        prizeCounts = _prizeCounts;
    }

    /**
     * @notice Calculates the tier index given the random numbers and masks
     * @param _randomNumberThisPick User random number for this Pick
     * @param _winningRandomNumber The winning number for this draw
     * @param _masks The pre-calculated bitmasks for the PrizeConfig
     * @return The position within the prize tier array (0 = top prize, 1 = runner-up prize, etc)
     */
    function _calculateTierIndex(
        uint256 _randomNumberThisPick,
        uint256 _winningRandomNumber,
        uint256[] memory _masks
    ) internal pure returns (uint8) {
        uint8 _numberOfMatches;
        uint8 _masksLength = uint8(_masks.length);

        // main number matching loop
        for (uint8 matchIndex = 0; matchIndex < _masksLength; matchIndex++) {
            uint256 _mask = _masks[matchIndex];

            if ((_randomNumberThisPick & _mask) != (_winningRandomNumber & _mask)) {
                // there are no more sequential matches since this comparison is not a match
                if (_masksLength == _numberOfMatches) {
                    return 0;
                } else {
                    return _masksLength - _numberOfMatches;
                }
            }

            // else there was a match
            _numberOfMatches++;
        }

        return _masksLength - _numberOfMatches;
    }

    /**
     * @notice Creates an array of bitmasks equal to the PrizeConfig.matchCardinality length
     * @param _matchCardinality Match cardinality for Draw
     * @param _bitRangeSize Bit range size for Draw
     * @return Array of bitmasks
     */
    function _createBitMasks(uint8 _matchCardinality, uint8 _bitRangeSize)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256[] memory _masks = new uint256[](_matchCardinality);
        _masks[0] = (2**_bitRangeSize) - 1;

        for (uint8 _maskIndex = 1; _maskIndex < _matchCardinality; _maskIndex++) {
            // shift mask bits to correct position and insert in result mask array
            _masks[_maskIndex] = _masks[_maskIndex - 1] << _bitRangeSize;
        }

        return _masks;
    }

    /**
     * @notice Calculates the expected prize fraction per PrizeConfig and prize tiers index
     * @param _prizeFraction Prize fraction for this PrizeConfig
     * @param _bitRangeSize Bit range size for Draw
     * @param _prizeConfigIndex Index of the prize tiers array to calculate
     * @return returns the fraction of the total prize (fixed point 9 number)
     */
    function _calculatePrizeTierFraction(
        uint256 _prizeFraction,
        uint8 _bitRangeSize,
        uint256 _prizeConfigIndex
    ) internal pure returns (uint256) {
        // calculate number of prizes for that index
        uint256 numberOfPrizesForIndex = _numberOfPrizesForIndex(
            _bitRangeSize,
            _prizeConfigIndex
        );

        return _prizeFraction / numberOfPrizesForIndex;
    }

    /**
     * @notice Calculates the number of prizes for a given PrizeConfigIndex
     * @param _bitRangeSize Bit range size for Draw
     * @param _prizeConfigIndex Index of the PrizeConfig array to calculate
     * @return returns the fraction of the total prize (base 1e18)
     */
    function _numberOfPrizesForIndex(uint8 _bitRangeSize, uint256 _prizeConfigIndex)
        internal
        pure
        returns (uint256)
    {
        if (_prizeConfigIndex > 0) {
            return ( 1 << _bitRangeSize * _prizeConfigIndex ) - ( 1 << _bitRangeSize * (_prizeConfigIndex - 1) );
        } else {
            return 1;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@pooltogether/owner-manager-contracts/contracts/Ownable.sol";

import "./interfaces/IPrizeDistributor.sol";
import "./interfaces/IDrawCalculator.sol";

/**
    * @title  PoolTogether V4 PrizeDistributor
    * @author PoolTogether Inc Team
    * @notice The PrizeDistributor contract holds Tickets (captured interest) and distributes tickets to users with winning draw claims.
              PrizeDistributor uses an external IDrawCalculator to validate a users draw claim, before awarding payouts. To prevent users 
              from reclaiming prizes, a payout history for each draw claim is mapped to user accounts. Reclaiming a draw can occur
              if an "optimal" prize was not included in previous claim pick indices and the new claims updated payout is greater then
              the previous prize distributor claim payout.
*/
contract PrizeDistributor is IPrizeDistributor, Ownable {
    using SafeERC20 for IERC20;

    /* ============ Global Variables ============ */

    /// @notice DrawCalculator address
    IDrawCalculator internal drawCalculator;

    /// @notice Token address
    IERC20 internal immutable token;

    /// @notice Maps users => drawId => paid out balance
    mapping(address => mapping(uint256 => uint256)) internal userDrawPayouts;

    /* ============ Initialize ============ */

    /**
     * @notice Initialize PrizeDistributor smart contract.
     * @param _owner          Owner address
     * @param _token          Token address
     * @param _drawCalculator DrawCalculator address
     */
    constructor(
        address _owner,
        IERC20 _token,
        IDrawCalculator _drawCalculator
    ) Ownable(_owner) {
        _setDrawCalculator(_drawCalculator);
        require(address(_token) != address(0), "PrizeDistributor/token-not-zero-address");
        token = _token;
        emit TokenSet(_token);
    }

    /* ============ External Functions ============ */

    /// @inheritdoc IPrizeDistributor
    function claim(
        address _user,
        uint32[] calldata _drawIds,
        bytes calldata _data
    ) external override returns (uint256) {
        
        uint256 totalPayout;
        
        (uint256[] memory drawPayouts, ) = drawCalculator.calculate(_user, _drawIds, _data); // neglect the prizeCounts since we are not interested in them here

        uint256 drawPayoutsLength = drawPayouts.length;
        for (uint256 payoutIndex = 0; payoutIndex < drawPayoutsLength; payoutIndex++) {
            uint32 drawId = _drawIds[payoutIndex];
            uint256 payout = drawPayouts[payoutIndex];
            uint256 oldPayout = _getDrawPayoutBalanceOf(_user, drawId);
            uint256 payoutDiff = 0;

            // helpfully short-circuit, in case the user screwed something up.
            require(payout > oldPayout, "PrizeDistributor/zero-payout");

            unchecked {
                payoutDiff = payout - oldPayout;
            }

            _setDrawPayoutBalanceOf(_user, drawId, payout);

            totalPayout += payoutDiff;

            emit ClaimedDraw(_user, drawId, payoutDiff);
        }

        _awardPayout(_user, totalPayout);

        return totalPayout;
    }

    /// @inheritdoc IPrizeDistributor
    function withdrawERC20(
        IERC20 _erc20Token,
        address _to,
        uint256 _amount
    ) external override onlyOwner returns (bool) {
        require(_to != address(0), "PrizeDistributor/recipient-not-zero-address");
        require(address(_erc20Token) != address(0), "PrizeDistributor/ERC20-not-zero-address");

        _erc20Token.safeTransfer(_to, _amount);

        emit ERC20Withdrawn(_erc20Token, _to, _amount);

        return true;
    }

    /// @inheritdoc IPrizeDistributor
    function getDrawCalculator() external view override returns (IDrawCalculator) {
        return drawCalculator;
    }

    /// @inheritdoc IPrizeDistributor
    function getDrawPayoutBalanceOf(address _user, uint32 _drawId)
        external
        view
        override
        returns (uint256)
    {
        return _getDrawPayoutBalanceOf(_user, _drawId);
    }

    /// @inheritdoc IPrizeDistributor
    function getToken() external view override returns (IERC20) {
        return token;
    }

    /// @inheritdoc IPrizeDistributor
    function setDrawCalculator(IDrawCalculator _newCalculator)
        external
        override
        onlyOwner
        returns (IDrawCalculator)
    {
        _setDrawCalculator(_newCalculator);
        return _newCalculator;
    }

    /* ============ Internal Functions ============ */

    function _getDrawPayoutBalanceOf(address _user, uint32 _drawId)
        internal
        view
        returns (uint256)
    {
        return userDrawPayouts[_user][_drawId];
    }

    function _setDrawPayoutBalanceOf(
        address _user,
        uint32 _drawId,
        uint256 _payout
    ) internal {
        userDrawPayouts[_user][_drawId] = _payout;
    }

    /**
     * @notice Sets DrawCalculator reference for individual draw id.
     * @param _newCalculator  DrawCalculator address
     */
    function _setDrawCalculator(IDrawCalculator _newCalculator) internal {
        require(address(_newCalculator) != address(0), "PrizeDistributor/calc-not-zero");
        drawCalculator = _newCalculator;

        emit DrawCalculatorSet(_newCalculator);
    }

    /**
     * @notice Transfer claimed draw(s) total payout to user.
     * @param _to      User address
     * @param _amount  Transfer amount
     */
    function _awardPayout(address _to, uint256 _amount) internal {
        token.safeTransfer(_to, _amount);
    }

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IDrawBuffer.sol";
import "./IDrawCalculator.sol";

/** @title  IPrizeDistributor
  * @author PoolTogether Inc Team
  * @notice The PrizeDistributor interface.
*/
interface IPrizeDistributor {

    /**
     * @notice Emit when user has claimed token from the PrizeDistributor.
     * @param user   User address receiving draw claim payouts
     * @param drawId Draw id that was paid out
     * @param payout Payout for draw
     */
    event ClaimedDraw(address indexed user, uint32 indexed drawId, uint256 payout);

    /**
     * @notice Emit when DrawCalculator is set.
     * @param calculator DrawCalculator address
     */
    event DrawCalculatorSet(IDrawCalculator indexed calculator);

    /**
     * @notice Emit when Token is set.
     * @param token Token address
     */
    event TokenSet(IERC20 indexed token);

    /**
     * @notice Emit when ERC20 tokens are withdrawn.
     * @param token  ERC20 token transferred.
     * @param to     Address that received funds.
     * @param amount Amount of tokens transferred.
     */
    event ERC20Withdrawn(IERC20 indexed token, address indexed to, uint256 amount);

    /**
     * @notice Claim prize payout(s) by submitting valid drawId(s) and winning pick indice(s). The user address
               is used as the "seed" phrase to generate random numbers.
     * @dev    The claim function is public and any wallet may execute claim on behalf of another user.
               Prizes are always paid out to the designated user account and not the caller (msg.sender).
               Claiming prizes is not limited to a single transaction. Reclaiming can be executed
               subsequentially if an "optimal" prize was not included in previous claim pick indices. The
               payout difference for the new claim is calculated during the award process and transfered to user.
     * @param user    Address of user to claim awards for. Does NOT need to be msg.sender
     * @param drawIds Draw IDs from global DrawBuffer reference
     * @param data    The data to pass to the draw calculator
     * @return Total claim payout. May include calcuations from multiple draws.
     */
    function claim(
        address user,
        uint32[] calldata drawIds,
        bytes calldata data
    ) external returns (uint256);

    /**
        * @notice Read global DrawCalculator address.
        * @return IDrawCalculator
     */
    function getDrawCalculator() external view returns (IDrawCalculator);

    /**
        * @notice Get the amount that a user has already been paid out for a draw
        * @param user   User address
        * @param drawId Draw ID
     */
    function getDrawPayoutBalanceOf(address user, uint32 drawId) external view returns (uint256);

    /**
        * @notice Read global Ticket address.
        * @return IERC20
     */
    function getToken() external view returns (IERC20);

    /**
        * @notice Sets DrawCalculator reference contract.
        * @param newCalculator DrawCalculator address
        * @return New DrawCalculator address
     */
    function setDrawCalculator(IDrawCalculator newCalculator) external returns (IDrawCalculator);

    /**
        * @notice Transfer ERC20 tokens out of contract to recipient address.
        * @dev    Only callable by contract owner.
        * @param token  ERC20 token to transfer.
        * @param to     Recipient of the tokens.
        * @param amount Amount of tokens to transfer.
        * @return true if operation is successful.
    */
    function withdrawERC20(
        IERC20 token,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "./ITicket.sol";
import "./IDrawBuffer.sol";
import "../PrizeDistributionBuffer.sol";
import "../PrizeDistributor.sol";

/**
 * @title  PoolTogether V4 IDrawCalculator
 * @author PoolTogether Inc Team
 * @notice The DrawCalculator interface.
 */
interface IDrawCalculator {
    struct PickPrize {
        bool won;
        uint8 tierIndex;
    }

    ///@notice Emitted when the contract is initialized
    event Deployed(
        ITicket indexed ticket,
        IDrawBuffer indexed drawBuffer,
        IPrizeDistributionBuffer indexed prizeDistributionBuffer
    );

    ///@notice Emitted when the prizeDistributor is set/updated
    event PrizeDistributorSet(PrizeDistributor indexed prizeDistributor);

    /**
     * @notice Calculates the prize amount for a user for Multiple Draws. Typically called by a PrizeDistributor.
     * @param user User for which to calculate prize amount.
     * @param drawIds drawId array for which to calculate prize amounts for.
     * @param data The ABI encoded pick indices for all Draws. Expected to be winning picks. Pick indices must be less than the totalUserPicks.
     * @return List of awardable prize amounts ordered by drawId.
     */
    function calculate(
        address user,
        uint32[] calldata drawIds,
        bytes calldata data
    ) external view returns (uint256[] memory, bytes memory);

    /**
     * @notice Read global DrawBuffer variable.
     * @return IDrawBuffer
     */
    function getDrawBuffer() external view returns (IDrawBuffer);

    /**
     * @notice Read global prizeDistributionBuffer variable.
     * @return IPrizeDistributionBuffer
     */
    function getPrizeDistributionBuffer() external view returns (IPrizeDistributionBuffer);

    /**
     * @notice Returns a users balances expressed as a fraction of the total supply over time.
     * @param user The users address
     * @param drawIds The drawIds to consider
     * @return Array of balances
     */
    function getNormalizedBalancesForDrawIds(address user, uint32[] calldata drawIds)
        external
        view
        returns (uint256[] memory);

}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@pooltogether/owner-manager-contracts/contracts/Manageable.sol";

import "./libraries/DrawRingBufferLib.sol";
import "./interfaces/IPrizeDistributionBuffer.sol";

/**
  * @title  PoolTogether V4 PrizeDistributionBuffer
  * @author PoolTogether Inc Team
  * @notice The PrizeDistributionBuffer contract provides historical lookups of PrizeDistribution struct parameters (linked with a Draw ID) via a
            circular ring buffer. Historical PrizeDistribution parameters can be accessed on-chain using a drawId to calculate
            ring buffer storage slot. The PrizeDistribution parameters can be created by manager/owner and existing PrizeDistribution
            parameters can only be updated the owner. When adding a new PrizeDistribution basic sanity checks will be used to
            validate the incoming parameters.
*/
contract PrizeDistributionBuffer is IPrizeDistributionBuffer, Manageable {
    using DrawRingBufferLib for DrawRingBufferLib.Buffer;

    /// @notice The maximum cardinality of the prize distribution ring buffer.
    /// @dev even with daily draws, 256 will give us over 8 months of history.
    uint256 internal constant MAX_CARDINALITY = 256;

    /// @notice The ceiling for prize distributions.  1e9 = 100%.
    /// @dev It's fixed point 9 because 1e9 is the largest "1" that fits into 2**32
    uint256 internal constant TIERS_CEILING = 1e9;

    /// @notice Emitted when the contract is deployed.
    /// @param cardinality The maximum number of records in the buffer before they begin to expire.
    event Deployed(uint8 cardinality);

    /// @notice PrizeDistribution ring buffer history.
    IPrizeDistributionBuffer.PrizeDistribution[MAX_CARDINALITY]
        internal prizeDistributionRingBuffer;

    /// @notice Ring buffer metadata (nextIndex, lastId, cardinality)
    DrawRingBufferLib.Buffer internal bufferMetadata;

    /* ============ Constructor ============ */

    /**
     * @notice Constructor for PrizeDistributionBuffer
     * @param _owner Address of the PrizeDistributionBuffer owner
     * @param _cardinality Cardinality of the `bufferMetadata`
     */
    constructor(address _owner, uint8 _cardinality) Ownable(_owner) {
        bufferMetadata.cardinality = _cardinality;
        emit Deployed(_cardinality);
    }

    /* ============ External Functions ============ */

    /// @inheritdoc IPrizeDistributionBuffer
    function getBufferCardinality() external view override returns (uint32) {
        return bufferMetadata.cardinality;
    }

    /// @inheritdoc IPrizeDistributionBuffer
    function getPrizeDistribution(uint32 _drawId)
        external
        view
        override
        returns (IPrizeDistributionBuffer.PrizeDistribution memory)
    {
        return _getPrizeDistribution(bufferMetadata, _drawId);
    }

    /// @inheritdoc IPrizeDistributionSource
    function getPrizeDistributions(uint32[] calldata _drawIds)
        external
        view
        override
        returns (IPrizeDistributionBuffer.PrizeDistribution[] memory)
    {
        uint256 drawIdsLength = _drawIds.length;
        DrawRingBufferLib.Buffer memory buffer = bufferMetadata;
        IPrizeDistributionBuffer.PrizeDistribution[]
            memory _prizeDistributions = new IPrizeDistributionBuffer.PrizeDistribution[](
                drawIdsLength
            );

        for (uint256 i = 0; i < drawIdsLength; i++) {
            _prizeDistributions[i] = _getPrizeDistribution(buffer, _drawIds[i]);
        }

        return _prizeDistributions;
    }

    /// @inheritdoc IPrizeDistributionBuffer
    function getPrizeDistributionCount() external view override returns (uint32) {
        DrawRingBufferLib.Buffer memory buffer = bufferMetadata;

        if (buffer.lastDrawId == 0) {
            return 0;
        }

        uint32 bufferNextIndex = buffer.nextIndex;

        // If the buffer is full return the cardinality, else retun the nextIndex
        if (prizeDistributionRingBuffer[bufferNextIndex].matchCardinality != 0) {
            return buffer.cardinality;
        } else {
            return bufferNextIndex;
        }
    }

    /// @inheritdoc IPrizeDistributionBuffer
    function getNewestPrizeDistribution()
        external
        view
        override
        returns (IPrizeDistributionBuffer.PrizeDistribution memory prizeDistribution, uint32 drawId)
    {
        DrawRingBufferLib.Buffer memory buffer = bufferMetadata;

        return (prizeDistributionRingBuffer[buffer.getIndex(buffer.lastDrawId)], buffer.lastDrawId);
    }

    /// @inheritdoc IPrizeDistributionBuffer
    function getOldestPrizeDistribution()
        external
        view
        override
        returns (IPrizeDistributionBuffer.PrizeDistribution memory prizeDistribution, uint32 drawId)
    {
        DrawRingBufferLib.Buffer memory buffer = bufferMetadata;

        // if the ring buffer is full, the oldest is at the nextIndex
        prizeDistribution = prizeDistributionRingBuffer[buffer.nextIndex];

        // The PrizeDistribution at index 0 IS by default the oldest prizeDistribution.
        if (buffer.lastDrawId == 0) {
            drawId = 0; // return 0 to indicate no prizeDistribution ring buffer history
        } else if (prizeDistribution.bitRangeSize == 0) {
            // IF the next PrizeDistribution.bitRangeSize == 0 the ring buffer HAS NOT looped around so the oldest is the first entry.
            prizeDistribution = prizeDistributionRingBuffer[0];
            drawId = (buffer.lastDrawId + 1) - buffer.nextIndex;
        } else {
            // Calculates the drawId using the ring buffer cardinality
            // Sequential drawIds are gauranteed by DrawRingBufferLib.push()
            drawId = (buffer.lastDrawId + 1) - buffer.cardinality;
        }
    }

    /// @inheritdoc IPrizeDistributionBuffer
    function pushPrizeDistribution(
        uint32 _drawId,
        IPrizeDistributionBuffer.PrizeDistribution calldata _prizeDistribution
    ) external override onlyManagerOrOwner returns (bool) {
        return _pushPrizeDistribution(_drawId, _prizeDistribution);
    }

    /// @inheritdoc IPrizeDistributionBuffer
    function setPrizeDistribution(
        uint32 _drawId,
        IPrizeDistributionBuffer.PrizeDistribution calldata _prizeDistribution
    ) external override onlyOwner returns (uint32) {
        DrawRingBufferLib.Buffer memory buffer = bufferMetadata;
        uint32 index = buffer.getIndex(_drawId);
        prizeDistributionRingBuffer[index] = _prizeDistribution;

        emit PrizeDistributionSet(_drawId, _prizeDistribution);

        return _drawId;
    }

    /* ============ Internal Functions ============ */

    /**
     * @notice Gets the PrizeDistributionBuffer for a drawId
     * @param _buffer DrawRingBufferLib.Buffer
     * @param _drawId drawId
     */
    function _getPrizeDistribution(DrawRingBufferLib.Buffer memory _buffer, uint32 _drawId)
        internal
        view
        returns (IPrizeDistributionBuffer.PrizeDistribution memory)
    {
        return prizeDistributionRingBuffer[_buffer.getIndex(_drawId)];
    }

    /**
     * @notice Set newest PrizeDistributionBuffer in ring buffer storage.
     * @param _drawId       drawId
     * @param _prizeDistribution PrizeDistributionBuffer struct
     */
    function _pushPrizeDistribution(
        uint32 _drawId,
        IPrizeDistributionBuffer.PrizeDistribution calldata _prizeDistribution
    ) internal returns (bool) {
        require(_drawId > 0, "DrawCalc/draw-id-gt-0");
        require(_prizeDistribution.matchCardinality > 0, "DrawCalc/matchCardinality-gt-0");
        require(
            _prizeDistribution.bitRangeSize <= 256 / _prizeDistribution.matchCardinality,
            "DrawCalc/bitRangeSize-too-large"
        );

        require(_prizeDistribution.bitRangeSize > 0, "DrawCalc/bitRangeSize-gt-0");
        require(_prizeDistribution.maxPicksPerUser > 0, "DrawCalc/maxPicksPerUser-gt-0");
        require(_prizeDistribution.expiryDuration > 0, "DrawCalc/expiryDuration-gt-0");

        // ensure that the sum of the tiers are not gt 100%
        uint256 sumTotalTiers = 0;
        uint256 tiersLength = _prizeDistribution.tiers.length;

        for (uint256 index = 0; index < tiersLength; index++) {
            uint256 tier = _prizeDistribution.tiers[index];
            sumTotalTiers += tier;
        }

        // Each tier amount stored as uint32 - summed can't exceed 1e9
        require(sumTotalTiers <= TIERS_CEILING, "DrawCalc/tiers-gt-100%");

        DrawRingBufferLib.Buffer memory buffer = bufferMetadata;

        // store the PrizeDistribution in the ring buffer
        prizeDistributionRingBuffer[buffer.nextIndex] = _prizeDistribution;

        // update the ring buffer data
        bufferMetadata = buffer.push(_drawId);

        emit PrizeDistributionSet(_drawId, _prizeDistribution);

        return true;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "./RingBufferLib.sol";

/// @title Library for creating and managing a draw ring buffer.
library DrawRingBufferLib {
    /// @notice Draw buffer struct.
    struct Buffer {
        uint32 lastDrawId;
        uint32 nextIndex;
        uint32 cardinality;
    }

    /// @notice Helper function to know if the draw ring buffer has been initialized.
    /// @dev since draws start at 1 and are monotonically increased, we know we are uninitialized if nextIndex = 0 and lastDrawId = 0.
    /// @param _buffer The buffer to check.
    function isInitialized(Buffer memory _buffer) internal pure returns (bool) {
        return !(_buffer.nextIndex == 0 && _buffer.lastDrawId == 0);
    }

    /// @notice Push a draw to the buffer.
    /// @param _buffer The buffer to push to.
    /// @param _drawId The drawID to push.
    /// @return The new buffer.
    function push(Buffer memory _buffer, uint32 _drawId) internal pure returns (Buffer memory) {
        require(!isInitialized(_buffer) || _drawId == _buffer.lastDrawId + 1, "DRB/must-be-contig");

        return
            Buffer({
                lastDrawId: _drawId,
                nextIndex: uint32(RingBufferLib.nextIndex(_buffer.nextIndex, _buffer.cardinality)),
                cardinality: _buffer.cardinality
            });
    }

    /// @notice Get draw ring buffer index pointer.
    /// @param _buffer The buffer to get the `nextIndex` from.
    /// @param _drawId The draw id to get the index for.
    /// @return The draw ring buffer index pointer.
    function getIndex(Buffer memory _buffer, uint32 _drawId) internal pure returns (uint32) {
        require(isInitialized(_buffer) && _drawId <= _buffer.lastDrawId, "DRB/future-draw");

        uint32 indexOffset = _buffer.lastDrawId - _drawId;
        require(indexOffset < _buffer.cardinality, "DRB/expired-draw");

        uint256 mostRecent = RingBufferLib.newestIndex(_buffer.nextIndex, _buffer.cardinality);

        return uint32(RingBufferLib.offset(uint32(mostRecent), indexOffset, _buffer.cardinality));
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "./IPrizeDistributionSource.sol";

/** @title  IPrizeDistributionBuffer
 * @author PoolTogether Inc Team
 * @notice The PrizeDistributionBuffer interface.
 */
interface IPrizeDistributionBuffer is IPrizeDistributionSource {
    /**
     * @notice Emit when PrizeDistribution is set.
     * @param drawId       Draw id
     * @param prizeDistribution IPrizeDistributionBuffer.PrizeDistribution
     */
    event PrizeDistributionSet(
        uint32 indexed drawId,
        IPrizeDistributionBuffer.PrizeDistribution prizeDistribution
    );

    /**
     * @notice Read a ring buffer cardinality
     * @return Ring buffer cardinality
     */
    function getBufferCardinality() external view returns (uint32);

    /**
     * @notice Read newest PrizeDistribution from prize distributions ring buffer.
     * @dev    Uses nextDrawIndex to calculate the most recently added PrizeDistribution.
     * @return prizeDistribution
     * @return drawId
     */
    function getNewestPrizeDistribution()
        external
        view
        returns (
            IPrizeDistributionBuffer.PrizeDistribution memory prizeDistribution,
            uint32 drawId
        );

    /**
     * @notice Read oldest PrizeDistribution from prize distributions ring buffer.
     * @dev    Finds the oldest Draw by buffer.nextIndex and buffer.lastDrawId
     * @return prizeDistribution
     * @return drawId
     */
    function getOldestPrizeDistribution()
        external
        view
        returns (
            IPrizeDistributionBuffer.PrizeDistribution memory prizeDistribution,
            uint32 drawId
        );

    /**
     * @notice Gets the PrizeDistributionBuffer for a drawId
     * @param drawId drawId
     * @return prizeDistribution
     */
    function getPrizeDistribution(uint32 drawId)
        external
        view
        returns (IPrizeDistributionBuffer.PrizeDistribution memory);

    /**
     * @notice Gets the number of PrizeDistributions stored in the prize distributions ring buffer.
     * @dev If no Draws have been pushed, it will return 0.
     * @dev If the ring buffer is full, it will return the cardinality.
     * @dev Otherwise, it will return the NewestPrizeDistribution index + 1.
     * @return Number of PrizeDistributions stored in the prize distributions ring buffer.
     */
    function getPrizeDistributionCount() external view returns (uint32);

    /**
     * @notice Adds new PrizeDistribution record to ring buffer storage.
     * @dev    Only callable by the owner or manager
     * @param drawId            Draw ID linked to PrizeDistribution parameters
     * @param prizeDistribution PrizeDistribution parameters struct
     */
    function pushPrizeDistribution(
        uint32 drawId,
        IPrizeDistributionBuffer.PrizeDistribution calldata prizeDistribution
    ) external returns (bool);

    /**
     * @notice Sets existing PrizeDistribution with new PrizeDistribution parameters in ring buffer storage.
     * @dev    Retroactively updates an existing PrizeDistribution and should be thought of as a "safety"
               fallback. If the manager is setting invalid PrizeDistribution parameters the Owner can update
               the invalid parameters with correct parameters.
     * @return drawId
     */
    function setPrizeDistribution(
        uint32 drawId,
        IPrizeDistributionBuffer.PrizeDistribution calldata draw
    ) external returns (uint32);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

/** @title IPrizeDistributionSource
 * @author PoolTogether Inc Team
 * @notice The PrizeDistributionSource interface.
 */
interface IPrizeDistributionSource {
    ///@notice PrizeDistribution struct created every draw
    ///@param bitRangeSize Decimal representation of bitRangeSize
    ///@param matchCardinality The number of numbers to consider in the 256 bit random number. Must be > 1 and < 256/bitRangeSize.
    ///@param startTimestampOffset The starting time offset in seconds from which Ticket balances are calculated.
    ///@param endTimestampOffset The end time offset in seconds from which Ticket balances are calculated.
    ///@param maxPicksPerUser Maximum number of picks a user can make in this draw
    ///@param expiryDuration Length of time in seconds the PrizeDistribution is valid for. Relative to the Draw.timestamp.
    ///@param numberOfPicks Number of picks this draw has (may vary across networks according to how much the network has contributed to the Reserve)
    ///@param tiers Array of prize tiers percentages, expressed in fraction form with base 1e9. Ordering: index0: grandPrize, index1: runnerUp, etc.
    ///@param prize Total prize amount available in this draw calculator for this draw (may vary from across networks)
    struct PrizeDistribution {
        uint8 bitRangeSize;
        uint8 matchCardinality;
        uint32 startTimestampOffset;
        uint32 endTimestampOffset;
        uint32 maxPicksPerUser;
        uint32 expiryDuration;
        uint104 numberOfPicks;
        uint32[16] tiers;
        uint256 prize;
    }

    /**
     * @notice Gets PrizeDistribution list from array of drawIds
     * @param drawIds drawIds to get PrizeDistribution for
     * @return prizeDistributionList
     */
    function getPrizeDistributions(uint32[] calldata drawIds)
        external
        view
        returns (PrizeDistribution[] memory);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "../DrawCalculatorV3.sol";

contract DrawCalculatorV3Harness is DrawCalculatorV3 {
    constructor(
        IGaugeController _gaugeController,
        IDrawBuffer _drawBuffer,
        IPrizeConfigHistory _prizeConfigHistory,
        address _owner
    ) DrawCalculatorV3(_gaugeController, _drawBuffer, _prizeConfigHistory, _owner) {}

    function calculateTierIndex(
        uint256 _randomNumberThisPick,
        uint256 _winningRandomNumber,
        uint256[] memory _masks
    ) public pure returns (uint256) {
        return _calculateTierIndex(_randomNumberThisPick, _winningRandomNumber, _masks);
    }

    function createBitMasks(uint8 _matchCardinality, uint8 _bitRangeSize)
        public
        pure
        returns (uint256[] memory)
    {
        return _createBitMasks(_matchCardinality, _bitRangeSize);
    }

    function calculatePrizeTierFraction(
        uint256 _prizeFraction,
        uint8 _bitRangeSize,
        uint256 _prizeConfigIndex
    ) external pure returns (uint256) {
        return _calculatePrizeTierFraction(_prizeFraction, _bitRangeSize, _prizeConfigIndex);
    }

    function numberOfPrizesForIndex(uint8 _bitRangeSize, uint256 _prizeConfigIndex)
        external
        pure
        returns (uint256)
    {
        return _numberOfPrizesForIndex(_bitRangeSize, _prizeConfigIndex);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "./interfaces/ITicket.sol";
import "./interfaces/IDrawBuffer.sol";
import "./interfaces/IPrizeDistributionSource.sol";
import "./interfaces/IDrawBeacon.sol";

import "./PrizeDistributor.sol";

/**
  * @title  PoolTogether V4 DrawCalculatorV2
  * @author PoolTogether Inc Team
  * @notice The DrawCalculator calculates a user's prize by matching a winning random number against
            their picks. A users picks are generated deterministically based on their address and balance
            of tickets held. Prize payouts are divided into multiple tiers: grand prize, second place, etc...
            A user with a higher average weighted balance (during each draw period) will be given a large number of
            picks to choose from, and thus a higher chance to match the winning numbers.
*/
contract DrawCalculatorV2 {
    /* ============ Variables ============ */

    /// @notice DrawBuffer address
    IDrawBuffer public immutable drawBuffer;

    /// @notice Ticket associated with DrawCalculator
    ITicket public immutable ticket;

    /// @notice The source in which the history of draw settings are stored as ring buffer.
    IPrizeDistributionSource public immutable prizeDistributionSource;

    /// @notice The tiers array length
    uint8 public constant TIERS_LENGTH = 16;

    /* ============ Events ============ */

    ///@notice Emitted when the contract is initialized
    event Deployed(
        ITicket indexed ticket,
        IDrawBuffer indexed drawBuffer,
        IPrizeDistributionSource indexed prizeDistributionSource
    );

    ///@notice Emitted when the prizeDistributor is set/updated
    event PrizeDistributorSet(PrizeDistributor indexed prizeDistributor);

    /* ============ Constructor ============ */

    /**
     * @notice Constructor for DrawCalculator
     * @param _ticket Ticket associated with this DrawCalculator
     * @param _drawBuffer The address of the draw buffer to push draws to
     * @param _prizeDistributionSource PrizeDistributionSource address
    */
    constructor(
        ITicket _ticket,
        IDrawBuffer _drawBuffer,
        IPrizeDistributionSource _prizeDistributionSource
    ) {
        require(address(_ticket) != address(0), "DrawCalc/ticket-not-zero");
        require(address(_prizeDistributionSource) != address(0), "DrawCalc/pdb-not-zero");
        require(address(_drawBuffer) != address(0), "DrawCalc/dh-not-zero");

        ticket = _ticket;
        drawBuffer = _drawBuffer;
        prizeDistributionSource = _prizeDistributionSource;

        emit Deployed(_ticket, _drawBuffer, _prizeDistributionSource);
    }

    /* ============ External Functions ============ */

    /**
     * @notice Calculates the prize amount for a user for Multiple Draws. Typically called by a PrizeDistributor.
     * @param _user User for which to calculate prize amount.
     * @param _drawIds drawId array for which to calculate prize amounts for.
     * @param _pickIndicesForDraws The ABI encoded pick indices for all Draws. Expected to be winning picks. Pick indices must be less than the totalUserPicks.
     * @return List of awardable prize amounts ordered by drawId.
    */
    function calculate(
        address _user,
        uint32[] calldata _drawIds,
        bytes calldata _pickIndicesForDraws
    ) external view returns (uint256[] memory, bytes memory) {
        uint64[][] memory pickIndices = abi.decode(_pickIndicesForDraws, (uint64 [][]));
        require(pickIndices.length == _drawIds.length, "DrawCalc/invalid-pick-indices-length");

        // READ list of IDrawBeacon.Draw using the drawIds from drawBuffer
        IDrawBeacon.Draw[] memory draws = drawBuffer.getDraws(_drawIds);

        // READ list of IPrizeDistributionSource.PrizeDistribution using the drawIds
        IPrizeDistributionSource.PrizeDistribution[] memory _prizeDistributions = prizeDistributionSource
            .getPrizeDistributions(_drawIds);

        // The userBalances are fractions representing their portion of the liquidity for a draw.
        uint256[] memory userBalances = _getNormalizedBalancesAt(_user, draws, _prizeDistributions);

        // The users address is hashed once.
        bytes32 _userRandomNumber = keccak256(abi.encodePacked(_user));

        return _calculatePrizesAwardable(
                userBalances,
                _userRandomNumber,
                draws,
                pickIndices,
                _prizeDistributions
            );
    }

    /**
     * @notice Read global DrawBuffer variable.
     * @return IDrawBuffer
    */
    function getDrawBuffer() external view returns (IDrawBuffer) {
        return drawBuffer;
    }

    /**
     * @notice Read global prizeDistributionSource variable.
     * @return IPrizeDistributionSource
    */
    function getPrizeDistributionSource()
        external
        view
        returns (IPrizeDistributionSource)
    {
        return prizeDistributionSource;
    }

    /**
     * @notice Returns a users balances expressed as a fraction of the total supply over time.
     * @param _user The users address
     * @param _drawIds The drawIds to consider
     * @return Array of balances
    */
    function getNormalizedBalancesForDrawIds(address _user, uint32[] calldata _drawIds)
        external
        view
        returns (uint256[] memory)
    {
        IDrawBeacon.Draw[] memory _draws = drawBuffer.getDraws(_drawIds);
        IPrizeDistributionSource.PrizeDistribution[] memory _prizeDistributions = prizeDistributionSource
            .getPrizeDistributions(_drawIds);

        return _getNormalizedBalancesAt(_user, _draws, _prizeDistributions);
    }

    /* ============ Internal Functions ============ */

    /**
     * @notice Calculates the prizes awardable for each Draw passed.
     * @param _normalizedUserBalances Fractions representing the user's portion of the liquidity for each draw.
     * @param _userRandomNumber       Random number of the user to consider over draws
     * @param _draws                  List of Draws
     * @param _pickIndicesForDraws    Pick indices for each Draw
     * @param _prizeDistributions     PrizeDistribution for each Draw

     */
    function _calculatePrizesAwardable(
        uint256[] memory _normalizedUserBalances,
        bytes32 _userRandomNumber,
        IDrawBeacon.Draw[] memory _draws,
        uint64[][] memory _pickIndicesForDraws,
        IPrizeDistributionSource.PrizeDistribution[] memory _prizeDistributions
    ) internal view returns (uint256[] memory prizesAwardable, bytes memory prizeCounts) {

        uint256[] memory _prizesAwardable = new uint256[](_normalizedUserBalances.length);
        uint256[][] memory _prizeCounts = new uint256[][](_normalizedUserBalances.length);

        uint64 timeNow = uint64(block.timestamp);

        // calculate prizes awardable for each Draw passed
        for (uint32 drawIndex = 0; drawIndex < _draws.length; drawIndex++) {
            require(timeNow < _draws[drawIndex].timestamp + _prizeDistributions[drawIndex].expiryDuration, "DrawCalc/draw-expired");

            uint64 totalUserPicks = _calculateNumberOfUserPicks(
                _prizeDistributions[drawIndex],
                _normalizedUserBalances[drawIndex]
            );

            (_prizesAwardable[drawIndex], _prizeCounts[drawIndex]) = _calculate(
                _draws[drawIndex].winningRandomNumber,
                totalUserPicks,
                _userRandomNumber,
                _pickIndicesForDraws[drawIndex],
                _prizeDistributions[drawIndex]
            );
        }

        prizeCounts = abi.encode(_prizeCounts);
        prizesAwardable = _prizesAwardable;
    }

    /**
     * @notice Calculates the number of picks a user gets for a Draw, considering the normalized user balance and the PrizeDistribution.
     * @dev Divided by 1e18 since the normalized user balance is stored as a fixed point 18 number
     * @param _prizeDistribution The PrizeDistribution to consider
     * @param _normalizedUserBalance The normalized user balances to consider
     * @return The number of picks a user gets for a Draw
     */
    function _calculateNumberOfUserPicks(
        IPrizeDistributionSource.PrizeDistribution memory _prizeDistribution,
        uint256 _normalizedUserBalance
    ) internal pure returns (uint64) {
        return uint64((_normalizedUserBalance * _prizeDistribution.numberOfPicks) / 1 ether);
    }

    /**
     * @notice Calculates the normalized balance of a user against the total supply for timestamps
     * @param _user The user to consider
     * @param _draws The draws we are looking at
     * @param _prizeDistributions The prize tiers to consider (needed for draw timestamp offsets)
     * @return An array of normalized balances
     */
    function _getNormalizedBalancesAt(
        address _user,
        IDrawBeacon.Draw[] memory _draws,
        IPrizeDistributionSource.PrizeDistribution[] memory _prizeDistributions
    ) internal view returns (uint256[] memory) {
        uint256 drawsLength = _draws.length;
        uint64[] memory _timestampsWithStartCutoffTimes = new uint64[](drawsLength);
        uint64[] memory _timestampsWithEndCutoffTimes = new uint64[](drawsLength);

        // generate timestamps with draw cutoff offsets included
        for (uint32 i = 0; i < drawsLength; i++) {
            unchecked {
                _timestampsWithStartCutoffTimes[i] =
                    _draws[i].timestamp - _prizeDistributions[i].startTimestampOffset;
                _timestampsWithEndCutoffTimes[i] =
                    _draws[i].timestamp - _prizeDistributions[i].endTimestampOffset;
            }
        }

        uint256[] memory balances = ticket.getAverageBalancesBetween(
            _user,
            _timestampsWithStartCutoffTimes,
            _timestampsWithEndCutoffTimes
        );

        uint256[] memory totalSupplies = ticket.getAverageTotalSuppliesBetween(
            _timestampsWithStartCutoffTimes,
            _timestampsWithEndCutoffTimes
        );

        uint256[] memory normalizedBalances = new uint256[](drawsLength);

        // divide balances by total supplies (normalize)
        for (uint256 i = 0; i < drawsLength; i++) {
            if(totalSupplies[i] == 0){
                normalizedBalances[i] = 0;
            }
            else {
                normalizedBalances[i] = (balances[i] * 1 ether) / totalSupplies[i];
            }
        }

        return normalizedBalances;
    }

    /**
     * @notice Calculates the prize amount for a PrizeDistribution over given picks
     * @param _winningRandomNumber Draw's winningRandomNumber
     * @param _totalUserPicks      number of picks the user gets for the Draw
     * @param _userRandomNumber    users randomNumber for that draw
     * @param _picks               users picks for that draw
     * @param _prizeDistribution   PrizeDistribution for that draw
     * @return prize (if any), prizeCounts (if any)
     */
    function _calculate(
        uint256 _winningRandomNumber,
        uint256 _totalUserPicks,
        bytes32 _userRandomNumber,
        uint64[] memory _picks,
        IPrizeDistributionSource.PrizeDistribution memory _prizeDistribution
    ) internal pure returns (uint256 prize, uint256[] memory prizeCounts) {

        // create bitmasks for the PrizeDistribution
        uint256[] memory masks = _createBitMasks(_prizeDistribution);
        uint32 picksLength = uint32(_picks.length);
        uint256[] memory _prizeCounts = new uint256[](_prizeDistribution.tiers.length);

        uint8 maxWinningTierIndex = 0;

        require(
            picksLength <= _prizeDistribution.maxPicksPerUser,
            "DrawCalc/exceeds-max-user-picks"
        );

        // for each pick, find number of matching numbers and calculate prize distributions index
        for (uint32 index = 0; index < picksLength; index++) {
            require(_picks[index] < _totalUserPicks, "DrawCalc/insufficient-user-picks");

            if (index > 0) {
                require(_picks[index] > _picks[index - 1], "DrawCalc/picks-ascending");
            }

            // hash the user random number with the pick value
            uint256 randomNumberThisPick = uint256(
                keccak256(abi.encode(_userRandomNumber, _picks[index]))
            );

            uint8 tiersIndex = _calculateTierIndex(
                randomNumberThisPick,
                _winningRandomNumber,
                masks
            );

            // there is prize for this tier index
            if (tiersIndex < TIERS_LENGTH) {
                if (tiersIndex > maxWinningTierIndex) {
                    maxWinningTierIndex = tiersIndex;
                }
                _prizeCounts[tiersIndex]++;
            }
        }

        // now calculate prizeFraction given prizeCounts
        uint256 prizeFraction = 0;
        uint256[] memory prizeTiersFractions = _calculatePrizeTierFractions(
            _prizeDistribution,
            maxWinningTierIndex
        );

        // multiple the fractions by the prizeCounts and add them up
        for (
            uint256 prizeCountIndex = 0;
            prizeCountIndex <= maxWinningTierIndex;
            prizeCountIndex++
        ) {
            if (_prizeCounts[prizeCountIndex] > 0) {
                prizeFraction +=
                    prizeTiersFractions[prizeCountIndex] *
                    _prizeCounts[prizeCountIndex];
            }
        }

        // return the absolute amount of prize awardable
        // div by 1e9 as prize tiers are base 1e9
        prize = (prizeFraction * _prizeDistribution.prize) / 1e9;
        prizeCounts = _prizeCounts;
    }

    ///@notice Calculates the tier index given the random numbers and masks
    ///@param _randomNumberThisPick users random number for this Pick
    ///@param _winningRandomNumber The winning number for this draw
    ///@param _masks The pre-calculate bitmasks for the prizeDistributions
    ///@return The position within the prize tier array (0 = top prize, 1 = runner-up prize, etc)
    function _calculateTierIndex(
        uint256 _randomNumberThisPick,
        uint256 _winningRandomNumber,
        uint256[] memory _masks
    ) internal pure returns (uint8) {
        uint8 numberOfMatches = 0;
        uint8 masksLength = uint8(_masks.length);

        // main number matching loop
        for (uint8 matchIndex = 0; matchIndex < masksLength; matchIndex++) {
            uint256 mask = _masks[matchIndex];

            if ((_randomNumberThisPick & mask) != (_winningRandomNumber & mask)) {
                // there are no more sequential matches since this comparison is not a match
                if (masksLength == numberOfMatches) {
                    return 0;
                } else {
                    return masksLength - numberOfMatches;
                }
            }

            // else there was a match
            numberOfMatches++;
        }

        return masksLength - numberOfMatches;
    }

    /**
     * @notice Create an array of bitmasks equal to the PrizeDistribution.matchCardinality length
     * @param _prizeDistribution The PrizeDistribution to use to calculate the masks
     * @return An array of bitmasks
     */
    function _createBitMasks(IPrizeDistributionSource.PrizeDistribution memory _prizeDistribution)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256[] memory masks = new uint256[](_prizeDistribution.matchCardinality);
        masks[0] =  (2**_prizeDistribution.bitRangeSize) - 1;

        for (uint8 maskIndex = 1; maskIndex < _prizeDistribution.matchCardinality; maskIndex++) {
            // shift mask bits to correct position and insert in result mask array
            masks[maskIndex] = masks[maskIndex - 1] << _prizeDistribution.bitRangeSize;
        }

        return masks;
    }

    /**
     * @notice Calculates the expected prize fraction per PrizeDistributions and distributionIndex
     * @param _prizeDistribution prizeDistribution struct for Draw
     * @param _prizeTierIndex Index of the prize tiers array to calculate
     * @return returns the fraction of the total prize (fixed point 9 number)
     */
    function _calculatePrizeTierFraction(
        IPrizeDistributionSource.PrizeDistribution memory _prizeDistribution,
        uint256 _prizeTierIndex
    ) internal pure returns (uint256) {
         // get the prize fraction at that index
        uint256 prizeFraction = _prizeDistribution.tiers[_prizeTierIndex];

        // calculate number of prizes for that index
        uint256 numberOfPrizesForIndex = _numberOfPrizesForIndex(
            _prizeDistribution.bitRangeSize,
            _prizeTierIndex
        );

        return prizeFraction / numberOfPrizesForIndex;
    }

    /**
     * @notice Generates an array of prize tiers fractions
     * @param _prizeDistribution prizeDistribution struct for Draw
     * @param maxWinningTierIndex Max length of the prize tiers array
     * @return returns an array of prize tiers fractions
     */
    function _calculatePrizeTierFractions(
        IPrizeDistributionSource.PrizeDistribution memory _prizeDistribution,
        uint8 maxWinningTierIndex
    ) internal pure returns (uint256[] memory) {
        uint256[] memory prizeDistributionFractions = new uint256[](
            maxWinningTierIndex + 1
        );

        for (uint8 i = 0; i <= maxWinningTierIndex; i++) {
            prizeDistributionFractions[i] = _calculatePrizeTierFraction(
                _prizeDistribution,
                i
            );
        }

        return prizeDistributionFractions;
    }

    /**
     * @notice Calculates the number of prizes for a given prizeDistributionIndex
     * @param _bitRangeSize Bit range size for Draw
     * @param _prizeTierIndex Index of the prize tier array to calculate
     * @return returns the fraction of the total prize (base 1e18)
     */
    function _numberOfPrizesForIndex(uint8 _bitRangeSize, uint256 _prizeTierIndex)
        internal
        pure
        returns (uint256)
    {
        if (_prizeTierIndex > 0) {
            return ( 1 << _bitRangeSize * _prizeTierIndex ) - ( 1 << _bitRangeSize * (_prizeTierIndex - 1) );
        } else {
            return 1;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "../DrawCalculatorV2.sol";

contract DrawCalculatorV2Harness is DrawCalculatorV2 {
    constructor(
        ITicket _ticket,
        IDrawBuffer _drawBuffer,
        IPrizeDistributionSource _prizeDistributionSource
    ) DrawCalculatorV2(_ticket, _drawBuffer, _prizeDistributionSource) {}

    function calculateTierIndex(
        uint256 _randomNumberThisPick,
        uint256 _winningRandomNumber,
        uint256[] memory _masks
    ) public pure returns (uint256) {
        return _calculateTierIndex(_randomNumberThisPick, _winningRandomNumber, _masks);
    }

    function createBitMasks(IPrizeDistributionSource.PrizeDistribution calldata _prizeDistribution)
        public
        pure
        returns (uint256[] memory)
    {
        return _createBitMasks(_prizeDistribution);
    }

    ///@notice Calculates the expected prize fraction per prizeDistribution and prizeTierIndex
    ///@param _prizeDistribution prizeDistribution struct for Draw
    ///@param _prizeTierIndex Index of the prize tiers array to calculate
    ///@return returns the fraction of the total prize
    function calculatePrizeTierFraction(
        IPrizeDistributionSource.PrizeDistribution calldata _prizeDistribution,
        uint256 _prizeTierIndex
    ) external pure returns (uint256) {
        return _calculatePrizeTierFraction(_prizeDistribution, _prizeTierIndex);
    }

    function numberOfPrizesForIndex(uint8 _bitRangeSize, uint256 _prizeTierIndex)
        external
        pure
        returns (uint256)
    {
        return _numberOfPrizesForIndex(_bitRangeSize, _prizeTierIndex);
    }

    function calculateNumberOfUserPicks(
        IPrizeDistributionSource.PrizeDistribution memory _prizeDistribution,
        uint256 _normalizedUserBalance
    ) external pure returns (uint64) {
        return _calculateNumberOfUserPicks(_prizeDistribution, _normalizedUserBalance);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "../DrawBuffer.sol";
import "../interfaces/IDrawBeacon.sol";

contract DrawBufferHarness is DrawBuffer {
    constructor(address owner, uint8 card) DrawBuffer(owner, card) {}

    function addMultipleDraws(
        uint256 _start,
        uint256 _numberOfDraws,
        uint32 _timestamp,
        uint256 _winningRandomNumber
    ) external {
        for (uint256 index = _start; index <= _numberOfDraws; index++) {
            IDrawBeacon.Draw memory _draw = IDrawBeacon.Draw({
                winningRandomNumber: _winningRandomNumber,
                drawId: uint32(index),
                timestamp: _timestamp,
                beaconPeriodSeconds: 10,
                beaconPeriodStartedAt: 20
            });

            _pushDraw(_draw);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@pooltogether/owner-manager-contracts/contracts/Manageable.sol";

import "./interfaces/IDrawBuffer.sol";
import "./interfaces/IDrawBeacon.sol";
import "./libraries/DrawRingBufferLib.sol";

/**
  * @title  PoolTogether V4 DrawBuffer
  * @author PoolTogether Inc Team
  * @notice The DrawBuffer provides historical lookups of Draws via a circular ring buffer.
            Historical Draws can be accessed on-chain using a drawId to calculate ring buffer storage slot.
            The Draw settings can be created by manager/owner and existing Draws can only be updated the owner.
            Once a starting Draw has been added to the ring buffer, all following draws must have a sequential Draw ID.
    @dev    A DrawBuffer store a limited number of Draws before beginning to overwrite (managed via the cardinality) previous Draws.
    @dev    All mainnet DrawBuffer(s) are updated directly from a DrawBeacon, but non-mainnet DrawBuffer(s) (Matic, Optimism, Arbitrum, etc...)
            will receive a cross-chain message, duplicating the mainnet Draw configuration - enabling a prize savings liquidity network.
*/
contract DrawBuffer is IDrawBuffer, Manageable {
    using DrawRingBufferLib for DrawRingBufferLib.Buffer;

    /// @notice Draws ring buffer max length.
    uint16 public constant MAX_CARDINALITY = 256;

    /// @notice Draws ring buffer array.
    IDrawBeacon.Draw[MAX_CARDINALITY] private drawRingBuffer;

    /// @notice Holds ring buffer information
    DrawRingBufferLib.Buffer internal bufferMetadata;

    /* ============ Deploy ============ */

    /**
     * @notice Deploy DrawBuffer smart contract.
     * @param _owner Address of the owner of the DrawBuffer.
     * @param _cardinality Draw ring buffer cardinality.
     */
    constructor(address _owner, uint8 _cardinality) Ownable(_owner) {
        bufferMetadata.cardinality = _cardinality;
    }

    /* ============ External Functions ============ */

    /// @inheritdoc IDrawBuffer
    function getBufferCardinality() external view override returns (uint32) {
        return bufferMetadata.cardinality;
    }

    /// @inheritdoc IDrawBuffer
    function getDraw(uint32 drawId) external view override returns (IDrawBeacon.Draw memory) {
        return drawRingBuffer[_drawIdToDrawIndex(bufferMetadata, drawId)];
    }

    /// @inheritdoc IDrawBuffer
    function getDraws(uint32[] calldata _drawIds)
        external
        view
        override
        returns (IDrawBeacon.Draw[] memory)
    {
        IDrawBeacon.Draw[] memory draws = new IDrawBeacon.Draw[](_drawIds.length);
        DrawRingBufferLib.Buffer memory buffer = bufferMetadata;

        for (uint256 index = 0; index < _drawIds.length; index++) {
            draws[index] = drawRingBuffer[_drawIdToDrawIndex(buffer, _drawIds[index])];
        }

        return draws;
    }

    /// @inheritdoc IDrawBuffer
    function getDrawCount() external view override returns (uint32) {
        DrawRingBufferLib.Buffer memory buffer = bufferMetadata;

        if (buffer.lastDrawId == 0) {
            return 0;
        }

        uint32 bufferNextIndex = buffer.nextIndex;

        if (drawRingBuffer[bufferNextIndex].timestamp != 0) {
            return buffer.cardinality;
        } else {
            return bufferNextIndex;
        }
    }

    /// @inheritdoc IDrawBuffer
    function getNewestDraw() external view override returns (IDrawBeacon.Draw memory) {
        return _getNewestDraw(bufferMetadata);
    }

    /// @inheritdoc IDrawBuffer
    function getOldestDraw() external view override returns (IDrawBeacon.Draw memory) {
        // oldest draw should be next available index, otherwise it's at 0
        DrawRingBufferLib.Buffer memory buffer = bufferMetadata;
        IDrawBeacon.Draw memory draw = drawRingBuffer[buffer.nextIndex];

        if (draw.timestamp == 0) {
            // if draw is not init, then use draw at 0
            draw = drawRingBuffer[0];
        }

        return draw;
    }

    /// @inheritdoc IDrawBuffer
    function pushDraw(IDrawBeacon.Draw memory _draw)
        external
        override
        onlyManagerOrOwner
        returns (uint32)
    {
        return _pushDraw(_draw);
    }

    /// @inheritdoc IDrawBuffer
    function setDraw(IDrawBeacon.Draw memory _newDraw) external override onlyOwner returns (uint32) {
        DrawRingBufferLib.Buffer memory buffer = bufferMetadata;
        uint32 index = buffer.getIndex(_newDraw.drawId);
        drawRingBuffer[index] = _newDraw;
        emit DrawSet(_newDraw.drawId, _newDraw);
        return _newDraw.drawId;
    }

    /* ============ Internal Functions ============ */

    /**
     * @notice Convert a Draw.drawId to a Draws ring buffer index pointer.
     * @dev    The getNewestDraw.drawId() is used to calculate a Draws ID delta position.
     * @param _drawId Draw.drawId
     * @return Draws ring buffer index pointer
     */
    function _drawIdToDrawIndex(DrawRingBufferLib.Buffer memory _buffer, uint32 _drawId)
        internal
        pure
        returns (uint32)
    {
        return _buffer.getIndex(_drawId);
    }

    /**
     * @notice Read newest Draw from the draws ring buffer.
     * @dev    Uses the lastDrawId to calculate the most recently added Draw.
     * @param _buffer Draw ring buffer
     * @return IDrawBeacon.Draw
     */
    function _getNewestDraw(DrawRingBufferLib.Buffer memory _buffer)
        internal
        view
        returns (IDrawBeacon.Draw memory)
    {
        return drawRingBuffer[_buffer.getIndex(_buffer.lastDrawId)];
    }

    /**
     * @notice Push Draw onto draws ring buffer history.
     * @dev    Push new draw onto draws list via authorized manager or owner.
     * @param _newDraw IDrawBeacon.Draw
     * @return Draw.drawId
     */
    function _pushDraw(IDrawBeacon.Draw memory _newDraw) internal returns (uint32) {
        DrawRingBufferLib.Buffer memory _buffer = bufferMetadata;
        drawRingBuffer[_buffer.nextIndex] = _newDraw;
        bufferMetadata = _buffer.push(_newDraw.drawId);

        emit DrawSet(_newDraw.drawId, _newDraw);

        return _newDraw.drawId;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "../../libraries/DrawRingBufferLib.sol";

/**
 * @title  Expose the DrawRingBufferLib for unit tests
 * @author PoolTogether Inc.
 */
contract DrawRingBufferLibHarness {
    using DrawRingBufferLib for DrawRingBufferLib.Buffer;

    uint16 public constant MAX_CARDINALITY = 256;
    DrawRingBufferLib.Buffer internal bufferMetadata;

    constructor(uint8 _cardinality) {
        bufferMetadata.cardinality = _cardinality;
    }

    function _push(DrawRingBufferLib.Buffer memory _buffer, uint32 _drawId)
        external
        pure
        returns (DrawRingBufferLib.Buffer memory)
    {
        return DrawRingBufferLib.push(_buffer, _drawId);
    }

    function _getIndex(DrawRingBufferLib.Buffer memory _buffer, uint32 _drawId)
        external
        pure
        returns (uint32)
    {
        return DrawRingBufferLib.getIndex(_buffer, _drawId);
    }

    function _isInitialized(DrawRingBufferLib.Buffer memory _buffer) external pure returns (bool) {
        return DrawRingBufferLib.isInitialized(_buffer);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "../libraries/DrawRingBufferLib.sol";

/**
 * @title  Expose the DrawRingBufferLibrary for unit tests
 * @author PoolTogether Inc.
 */
contract DrawRingBufferLibExposed {
    using DrawRingBufferLib for DrawRingBufferLib.Buffer;

    uint16 public constant MAX_CARDINALITY = 256;
    DrawRingBufferLib.Buffer internal bufferMetadata;

    constructor(uint8 _cardinality) {
        bufferMetadata.cardinality = _cardinality;
    }

    function _push(DrawRingBufferLib.Buffer memory _buffer, uint32 _drawId)
        external
        pure
        returns (DrawRingBufferLib.Buffer memory)
    {
        return DrawRingBufferLib.push(_buffer, _drawId);
    }

    function _getIndex(DrawRingBufferLib.Buffer memory _buffer, uint32 _drawId)
        external
        pure
        returns (uint32)
    {
        return DrawRingBufferLib.getIndex(_buffer, _drawId);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "./interfaces/IDrawCalculator.sol";
import "./interfaces/ITicket.sol";
import "./interfaces/IDrawBuffer.sol";
import "./interfaces/IPrizeDistributionBuffer.sol";
import "./interfaces/IDrawBeacon.sol";

/**
  * @title  PoolTogether V4 DrawCalculator
  * @author PoolTogether Inc Team
  * @notice The DrawCalculator calculates a user's prize by matching a winning random number against
            their picks. A users picks are generated deterministically based on their address and balance
            of tickets held. Prize payouts are divided into multiple tiers: grand prize, second place, etc...
            A user with a higher average weighted balance (during each draw period) will be given a large number of
            picks to choose from, and thus a higher chance to match the winning numbers.
*/
contract DrawCalculator is IDrawCalculator {

    /// @notice DrawBuffer address
    IDrawBuffer public immutable drawBuffer;

    /// @notice Ticket associated with DrawCalculator
    ITicket public immutable ticket;

    /// @notice The stored history of draw settings.  Stored as ring buffer.
    IPrizeDistributionBuffer public immutable prizeDistributionBuffer;

    /// @notice The tiers array length
    uint8 public constant TIERS_LENGTH = 16;

    /* ============ Constructor ============ */

    /// @notice Constructor for DrawCalculator
    /// @param _ticket Ticket associated with this DrawCalculator
    /// @param _drawBuffer The address of the draw buffer to push draws to
    /// @param _prizeDistributionBuffer PrizeDistributionBuffer address
    constructor(
        ITicket _ticket,
        IDrawBuffer _drawBuffer,
        IPrizeDistributionBuffer _prizeDistributionBuffer
    ) {
        require(address(_ticket) != address(0), "DrawCalc/ticket-not-zero");
        require(address(_prizeDistributionBuffer) != address(0), "DrawCalc/pdb-not-zero");
        require(address(_drawBuffer) != address(0), "DrawCalc/dh-not-zero");

        ticket = _ticket;
        drawBuffer = _drawBuffer;
        prizeDistributionBuffer = _prizeDistributionBuffer;

        emit Deployed(_ticket, _drawBuffer, _prizeDistributionBuffer);
    }

    /* ============ External Functions ============ */

    /// @inheritdoc IDrawCalculator
    function calculate(
        address _user,
        uint32[] calldata _drawIds,
        bytes calldata _pickIndicesForDraws
    ) external view override returns (uint256[] memory, bytes memory) {
        uint64[][] memory pickIndices = abi.decode(_pickIndicesForDraws, (uint64 [][]));
        require(pickIndices.length == _drawIds.length, "DrawCalc/invalid-pick-indices-length");

        // READ list of IDrawBeacon.Draw using the drawIds from drawBuffer
        IDrawBeacon.Draw[] memory draws = drawBuffer.getDraws(_drawIds);

        // READ list of IPrizeDistributionBuffer.PrizeDistribution using the drawIds
        IPrizeDistributionBuffer.PrizeDistribution[] memory _prizeDistributions = prizeDistributionBuffer
            .getPrizeDistributions(_drawIds);

        // The userBalances are fractions representing their portion of the liquidity for a draw.
        uint256[] memory userBalances = _getNormalizedBalancesAt(_user, draws, _prizeDistributions);

        // The users address is hashed once.
        bytes32 _userRandomNumber = keccak256(abi.encodePacked(_user));

        return _calculatePrizesAwardable(
                userBalances,
                _userRandomNumber,
                draws,
                pickIndices,
                _prizeDistributions
            );
    }

    /// @inheritdoc IDrawCalculator
    function getDrawBuffer() external view override returns (IDrawBuffer) {
        return drawBuffer;
    }

    /// @inheritdoc IDrawCalculator
    function getPrizeDistributionBuffer()
        external
        view
        override
        returns (IPrizeDistributionBuffer)
    {
        return prizeDistributionBuffer;
    }

    /// @inheritdoc IDrawCalculator
    function getNormalizedBalancesForDrawIds(address _user, uint32[] calldata _drawIds)
        external
        view
        override
        returns (uint256[] memory)
    {
        IDrawBeacon.Draw[] memory _draws = drawBuffer.getDraws(_drawIds);
        IPrizeDistributionBuffer.PrizeDistribution[] memory _prizeDistributions = prizeDistributionBuffer
            .getPrizeDistributions(_drawIds);

        return _getNormalizedBalancesAt(_user, _draws, _prizeDistributions);
    }

    /* ============ Internal Functions ============ */

    /**
     * @notice Calculates the prizes awardable for each Draw passed.
     * @param _normalizedUserBalances Fractions representing the user's portion of the liquidity for each draw.
     * @param _userRandomNumber       Random number of the user to consider over draws
     * @param _draws                  List of Draws
     * @param _pickIndicesForDraws    Pick indices for each Draw
     * @param _prizeDistributions     PrizeDistribution for each Draw

     */
    function _calculatePrizesAwardable(
        uint256[] memory _normalizedUserBalances,
        bytes32 _userRandomNumber,
        IDrawBeacon.Draw[] memory _draws,
        uint64[][] memory _pickIndicesForDraws,
        IPrizeDistributionBuffer.PrizeDistribution[] memory _prizeDistributions
    ) internal view returns (uint256[] memory prizesAwardable, bytes memory prizeCounts) {

        uint256[] memory _prizesAwardable = new uint256[](_normalizedUserBalances.length);
        uint256[][] memory _prizeCounts = new uint256[][](_normalizedUserBalances.length);

        uint64 timeNow = uint64(block.timestamp);

        // calculate prizes awardable for each Draw passed
        for (uint32 drawIndex = 0; drawIndex < _draws.length; drawIndex++) {
            require(timeNow < _draws[drawIndex].timestamp + _prizeDistributions[drawIndex].expiryDuration, "DrawCalc/draw-expired");

            uint64 totalUserPicks = _calculateNumberOfUserPicks(
                _prizeDistributions[drawIndex],
                _normalizedUserBalances[drawIndex]
            );

            (_prizesAwardable[drawIndex], _prizeCounts[drawIndex]) = _calculate(
                _draws[drawIndex].winningRandomNumber,
                totalUserPicks,
                _userRandomNumber,
                _pickIndicesForDraws[drawIndex],
                _prizeDistributions[drawIndex]
            );
        }

        prizeCounts = abi.encode(_prizeCounts);
        prizesAwardable = _prizesAwardable;
    }

    /**
     * @notice Calculates the number of picks a user gets for a Draw, considering the normalized user balance and the PrizeDistribution.
     * @dev Divided by 1e18 since the normalized user balance is stored as a fixed point 18 number
     * @param _prizeDistribution The PrizeDistribution to consider
     * @param _normalizedUserBalance The normalized user balances to consider
     * @return The number of picks a user gets for a Draw
     */
    function _calculateNumberOfUserPicks(
        IPrizeDistributionBuffer.PrizeDistribution memory _prizeDistribution,
        uint256 _normalizedUserBalance
    ) internal pure returns (uint64) {
        return uint64((_normalizedUserBalance * _prizeDistribution.numberOfPicks) / 1 ether);
    }

    /**
     * @notice Calculates the normalized balance of a user against the total supply for timestamps
     * @param _user The user to consider
     * @param _draws The draws we are looking at
     * @param _prizeDistributions The prize tiers to consider (needed for draw timestamp offsets)
     * @return An array of normalized balances
     */
    function _getNormalizedBalancesAt(
        address _user,
        IDrawBeacon.Draw[] memory _draws,
        IPrizeDistributionBuffer.PrizeDistribution[] memory _prizeDistributions
    ) internal view returns (uint256[] memory) {
        uint256 drawsLength = _draws.length;
        uint64[] memory _timestampsWithStartCutoffTimes = new uint64[](drawsLength);
        uint64[] memory _timestampsWithEndCutoffTimes = new uint64[](drawsLength);

        // generate timestamps with draw cutoff offsets included
        for (uint32 i = 0; i < drawsLength; i++) {
            unchecked {
                _timestampsWithStartCutoffTimes[i] =
                    _draws[i].timestamp - _prizeDistributions[i].startTimestampOffset;
                _timestampsWithEndCutoffTimes[i] =
                    _draws[i].timestamp - _prizeDistributions[i].endTimestampOffset;
            }
        }

        uint256[] memory balances = ticket.getAverageBalancesBetween(
            _user,
            _timestampsWithStartCutoffTimes,
            _timestampsWithEndCutoffTimes
        );

        uint256[] memory totalSupplies = ticket.getAverageTotalSuppliesBetween(
            _timestampsWithStartCutoffTimes,
            _timestampsWithEndCutoffTimes
        );

        uint256[] memory normalizedBalances = new uint256[](drawsLength);

        // divide balances by total supplies (normalize)
        for (uint256 i = 0; i < drawsLength; i++) {
            if(totalSupplies[i] == 0){
                normalizedBalances[i] = 0;
            }
            else {
                normalizedBalances[i] = (balances[i] * 1 ether) / totalSupplies[i];
            }
        }

        return normalizedBalances;
    }

    /**
     * @notice Calculates the prize amount for a PrizeDistribution over given picks
     * @param _winningRandomNumber Draw's winningRandomNumber
     * @param _totalUserPicks      number of picks the user gets for the Draw
     * @param _userRandomNumber    users randomNumber for that draw
     * @param _picks               users picks for that draw
     * @param _prizeDistribution   PrizeDistribution for that draw
     * @return prize (if any), prizeCounts (if any)
     */
    function _calculate(
        uint256 _winningRandomNumber,
        uint256 _totalUserPicks,
        bytes32 _userRandomNumber,
        uint64[] memory _picks,
        IPrizeDistributionBuffer.PrizeDistribution memory _prizeDistribution
    ) internal pure returns (uint256 prize, uint256[] memory prizeCounts) {

        // create bitmasks for the PrizeDistribution
        uint256[] memory masks = _createBitMasks(_prizeDistribution);
        uint32 picksLength = uint32(_picks.length);
        uint256[] memory _prizeCounts = new uint256[](_prizeDistribution.tiers.length);

        uint8 maxWinningTierIndex = 0;

        require(
            picksLength <= _prizeDistribution.maxPicksPerUser,
            "DrawCalc/exceeds-max-user-picks"
        );

        // for each pick, find number of matching numbers and calculate prize distributions index
        for (uint32 index = 0; index < picksLength; index++) {
            require(_picks[index] < _totalUserPicks, "DrawCalc/insufficient-user-picks");

            if (index > 0) {
                require(_picks[index] > _picks[index - 1], "DrawCalc/picks-ascending");
            }

            // hash the user random number with the pick value
            uint256 randomNumberThisPick = uint256(
                keccak256(abi.encode(_userRandomNumber, _picks[index]))
            );

            uint8 tiersIndex = _calculateTierIndex(
                randomNumberThisPick,
                _winningRandomNumber,
                masks
            );

            // there is prize for this tier index
            if (tiersIndex < TIERS_LENGTH) {
                if (tiersIndex > maxWinningTierIndex) {
                    maxWinningTierIndex = tiersIndex;
                }
                _prizeCounts[tiersIndex]++;
            }
        }

        // now calculate prizeFraction given prizeCounts
        uint256 prizeFraction = 0;
        uint256[] memory prizeTiersFractions = _calculatePrizeTierFractions(
            _prizeDistribution,
            maxWinningTierIndex
        );

        // multiple the fractions by the prizeCounts and add them up
        for (
            uint256 prizeCountIndex = 0;
            prizeCountIndex <= maxWinningTierIndex;
            prizeCountIndex++
        ) {
            if (_prizeCounts[prizeCountIndex] > 0) {
                prizeFraction +=
                    prizeTiersFractions[prizeCountIndex] *
                    _prizeCounts[prizeCountIndex];
            }
        }

        // return the absolute amount of prize awardable
        // div by 1e9 as prize tiers are base 1e9
        prize = (prizeFraction * _prizeDistribution.prize) / 1e9;
        prizeCounts = _prizeCounts;
    }

    ///@notice Calculates the tier index given the random numbers and masks
    ///@param _randomNumberThisPick users random number for this Pick
    ///@param _winningRandomNumber The winning number for this draw
    ///@param _masks The pre-calculate bitmasks for the prizeDistributions
    ///@return The position within the prize tier array (0 = top prize, 1 = runner-up prize, etc)
    function _calculateTierIndex(
        uint256 _randomNumberThisPick,
        uint256 _winningRandomNumber,
        uint256[] memory _masks
    ) internal pure returns (uint8) {
        uint8 numberOfMatches = 0;
        uint8 masksLength = uint8(_masks.length);

        // main number matching loop
        for (uint8 matchIndex = 0; matchIndex < masksLength; matchIndex++) {
            uint256 mask = _masks[matchIndex];

            if ((_randomNumberThisPick & mask) != (_winningRandomNumber & mask)) {
                // there are no more sequential matches since this comparison is not a match
                if (masksLength == numberOfMatches) {
                    return 0;
                } else {
                    return masksLength - numberOfMatches;
                }
            }

            // else there was a match
            numberOfMatches++;
        }

        return masksLength - numberOfMatches;
    }

    /**
     * @notice Create an array of bitmasks equal to the PrizeDistribution.matchCardinality length
     * @param _prizeDistribution The PrizeDistribution to use to calculate the masks
     * @return An array of bitmasks
     */
    function _createBitMasks(IPrizeDistributionBuffer.PrizeDistribution memory _prizeDistribution)
        internal
        pure
        returns (uint256[] memory)
    {
        uint256[] memory masks = new uint256[](_prizeDistribution.matchCardinality);
        masks[0] =  (2**_prizeDistribution.bitRangeSize) - 1;

        for (uint8 maskIndex = 1; maskIndex < _prizeDistribution.matchCardinality; maskIndex++) {
            // shift mask bits to correct position and insert in result mask array
            masks[maskIndex] = masks[maskIndex - 1] << _prizeDistribution.bitRangeSize;
        }

        return masks;
    }

    /**
     * @notice Calculates the expected prize fraction per PrizeDistributions and distributionIndex
     * @param _prizeDistribution prizeDistribution struct for Draw
     * @param _prizeTierIndex Index of the prize tiers array to calculate
     * @return returns the fraction of the total prize (fixed point 9 number)
     */
    function _calculatePrizeTierFraction(
        IPrizeDistributionBuffer.PrizeDistribution memory _prizeDistribution,
        uint256 _prizeTierIndex
    ) internal pure returns (uint256) {
         // get the prize fraction at that index
        uint256 prizeFraction = _prizeDistribution.tiers[_prizeTierIndex];

        // calculate number of prizes for that index
        uint256 numberOfPrizesForIndex = _numberOfPrizesForIndex(
            _prizeDistribution.bitRangeSize,
            _prizeTierIndex
        );

        return prizeFraction / numberOfPrizesForIndex;
    }

    /**
     * @notice Generates an array of prize tiers fractions
     * @param _prizeDistribution prizeDistribution struct for Draw
     * @param maxWinningTierIndex Max length of the prize tiers array
     * @return returns an array of prize tiers fractions
     */
    function _calculatePrizeTierFractions(
        IPrizeDistributionBuffer.PrizeDistribution memory _prizeDistribution,
        uint8 maxWinningTierIndex
    ) internal pure returns (uint256[] memory) {
        uint256[] memory prizeDistributionFractions = new uint256[](
            maxWinningTierIndex + 1
        );

        for (uint8 i = 0; i <= maxWinningTierIndex; i++) {
            prizeDistributionFractions[i] = _calculatePrizeTierFraction(
                _prizeDistribution,
                i
            );
        }

        return prizeDistributionFractions;
    }

    /**
     * @notice Calculates the number of prizes for a given prizeDistributionIndex
     * @param _bitRangeSize Bit range size for Draw
     * @param _prizeTierIndex Index of the prize tier array to calculate
     * @return returns the fraction of the total prize (base 1e18)
     */
    function _numberOfPrizesForIndex(uint8 _bitRangeSize, uint256 _prizeTierIndex)
        internal
        pure
        returns (uint256)
    {
        if (_prizeTierIndex > 0) {
            return ( 1 << _bitRangeSize * _prizeTierIndex ) - ( 1 << _bitRangeSize * (_prizeTierIndex - 1) );
        } else {
            return 1;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "../DrawCalculator.sol";

contract DrawCalculatorHarness is DrawCalculator {
    constructor(
        ITicket _ticket,
        IDrawBuffer _drawBuffer,
        IPrizeDistributionBuffer _prizeDistributionBuffer
    ) DrawCalculator(_ticket, _drawBuffer, _prizeDistributionBuffer) {}

    function calculateTierIndex(
        uint256 _randomNumberThisPick,
        uint256 _winningRandomNumber,
        uint256[] memory _masks
    ) public pure returns (uint256) {
        return _calculateTierIndex(_randomNumberThisPick, _winningRandomNumber, _masks);
    }

    function createBitMasks(IPrizeDistributionBuffer.PrizeDistribution calldata _prizeDistribution)
        public
        pure
        returns (uint256[] memory)
    {
        return _createBitMasks(_prizeDistribution);
    }

    ///@notice Calculates the expected prize fraction per prizeDistribution and prizeTierIndex
    ///@param _prizeDistribution prizeDistribution struct for Draw
    ///@param _prizeTierIndex Index of the prize tiers array to calculate
    ///@return returns the fraction of the total prize
    function calculatePrizeTierFraction(
        IPrizeDistributionBuffer.PrizeDistribution calldata _prizeDistribution,
        uint256 _prizeTierIndex
    ) external pure returns (uint256) {
        return _calculatePrizeTierFraction(_prizeDistribution, _prizeTierIndex);
    }

    function numberOfPrizesForIndex(uint8 _bitRangeSize, uint256 _prizeTierIndex)
        external
        pure
        returns (uint256)
    {
        return _numberOfPrizesForIndex(_bitRangeSize, _prizeTierIndex);
    }

    function calculateNumberOfUserPicks(
        IPrizeDistributionBuffer.PrizeDistribution memory _prizeDistribution,
        uint256 _normalizedUserBalance
    ) external pure returns (uint64) {
        return _calculateNumberOfUserPicks(_prizeDistribution, _normalizedUserBalance);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@pooltogether/pooltogether-rng-contracts/contracts/RNGInterface.sol";

import "../DrawBeacon.sol";
import "../interfaces/IDrawBuffer.sol";

contract DrawBeaconHarness is DrawBeacon {
    constructor(
        address _owner,
        IDrawBuffer _drawBuffer,
        RNGInterface _rng,
        uint32 _nextDrawId,
        uint64 _beaconPeriodStart,
        uint32 _drawPeriodSeconds,
        uint32 _rngTimeout
    ) DrawBeacon(_owner, _drawBuffer, _rng, _nextDrawId, _beaconPeriodStart, _drawPeriodSeconds, _rngTimeout) {}

    uint64 internal time;

    function setCurrentTime(uint64 _time) external {
        time = _time;
    }

    function _currentTime() internal view override returns (uint64) {
        return time;
    }

    function currentTime() external view returns (uint64) {
        return _currentTime();
    }

    function _currentTimeInternal() external view returns (uint64) {
        return super._currentTime();
    }

    function setRngRequest(uint32 requestId, uint32 lockBlock) external {
        rngRequest.id = requestId;
        rngRequest.lockBlock = lockBlock;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@pooltogether/pooltogether-rng-contracts/contracts/RNGInterface.sol";
import "@pooltogether/owner-manager-contracts/contracts/Ownable.sol";

import "./interfaces/IDrawBeacon.sol";
import "./interfaces/IDrawBuffer.sol";


/**
  * @title  PoolTogether V4 DrawBeacon
  * @author PoolTogether Inc Team
  * @notice Manages RNG (random number generator) requests and pushing Draws onto DrawBuffer.
            The DrawBeacon has 3 major actions for requesting a random number: start, cancel and complete.
            To create a new Draw, the user requests a new random number from the RNG service.
            When the random number is available, the user can create the draw using the create() method
            which will push the draw onto the DrawBuffer.
            If the RNG service fails to deliver a rng, when the request timeout elapses, the user can cancel the request.
*/
contract DrawBeacon is IDrawBeacon, Ownable {
    using SafeCast for uint256;
    using SafeERC20 for IERC20;

    /* ============ Variables ============ */

    /// @notice RNG contract interface
    RNGInterface internal rng;

    /// @notice Current RNG Request
    RngRequest internal rngRequest;

    /// @notice DrawBuffer address
    IDrawBuffer internal drawBuffer;

    /**
     * @notice RNG Request Timeout.  In fact, this is really a "complete draw" timeout.
     * @dev If the rng completes the award can still be cancelled.
     */
    uint32 internal rngTimeout;

    /// @notice Seconds between beacon period request
    uint32 internal beaconPeriodSeconds;

    /// @notice Epoch timestamp when beacon period can start
    uint64 internal beaconPeriodStartedAt;

    /**
     * @notice Next Draw ID to use when pushing a Draw onto DrawBuffer
     * @dev Starts at 1. This way we know that no Draw has been recorded at 0.
     */
    uint32 internal nextDrawId;

    /* ============ Structs ============ */

    /**
     * @notice RNG Request
     * @param id          RNG request ID
     * @param lockBlock   Block number that the RNG request is locked
     * @param requestedAt Time when RNG is requested
     */
    struct RngRequest {
        uint32 id;
        uint32 lockBlock;
        uint64 requestedAt;
    }

    /* ============ Events ============ */

    /**
     * @notice Emit when the DrawBeacon is deployed.
     * @param nextDrawId Draw ID at which the DrawBeacon should start. Can't be inferior to 1.
     * @param beaconPeriodStartedAt Timestamp when beacon period starts.
     */
    event Deployed(
        uint32 nextDrawId,
        uint64 beaconPeriodStartedAt
    );

    /* ============ Modifiers ============ */

    modifier requireDrawNotStarted() {
        _requireDrawNotStarted();
        _;
    }

    modifier requireCanStartDraw() {
        require(_isBeaconPeriodOver(), "DrawBeacon/beacon-period-not-over");
        require(!isRngRequested(), "DrawBeacon/rng-already-requested");
        _;
    }

    modifier requireCanCompleteRngRequest() {
        require(isRngRequested(), "DrawBeacon/rng-not-requested");
        require(isRngCompleted(), "DrawBeacon/rng-not-complete");
        _;
    }

    /* ============ Constructor ============ */

    /**
     * @notice Deploy the DrawBeacon smart contract.
     * @param _owner Address of the DrawBeacon owner
     * @param _drawBuffer The address of the draw buffer to push draws to
     * @param _rng The RNG service to use
     * @param _nextDrawId Draw ID at which the DrawBeacon should start. Can't be inferior to 1.
     * @param _beaconPeriodStart The starting timestamp of the beacon period.
     * @param _beaconPeriodSeconds The duration of the beacon period in seconds
     */
    constructor(
        address _owner,
        IDrawBuffer _drawBuffer,
        RNGInterface _rng,
        uint32 _nextDrawId,
        uint64 _beaconPeriodStart,
        uint32 _beaconPeriodSeconds,
        uint32 _rngTimeout
    ) Ownable(_owner) {
        require(_beaconPeriodStart > 0, "DrawBeacon/beacon-period-greater-than-zero");
        require(address(_rng) != address(0), "DrawBeacon/rng-not-zero");
        require(_nextDrawId >= 1, "DrawBeacon/next-draw-id-gte-one");

        beaconPeriodStartedAt = _beaconPeriodStart;
        nextDrawId = _nextDrawId;

        _setBeaconPeriodSeconds(_beaconPeriodSeconds);
        _setDrawBuffer(_drawBuffer);
        _setRngService(_rng);
        _setRngTimeout(_rngTimeout);

        emit Deployed(_nextDrawId, _beaconPeriodStart);
        emit BeaconPeriodStarted(_beaconPeriodStart);
    }

    /* ============ Public Functions ============ */

    /**
     * @notice Returns whether the random number request has completed.
     * @return True if a random number request has completed, false otherwise.
     */
    function isRngCompleted() public view override returns (bool) {
        return rng.isRequestComplete(rngRequest.id);
    }

    /**
     * @notice Returns whether a random number has been requested
     * @return True if a random number has been requested, false otherwise.
     */
    function isRngRequested() public view override returns (bool) {
        return rngRequest.id != 0;
    }

    /**
     * @notice Returns whether the random number request has timed out.
     * @return True if a random number request has timed out, false otherwise.
     */
    function isRngTimedOut() public view override returns (bool) {
        if (rngRequest.requestedAt == 0) {
            return false;
        } else {
            return rngTimeout + rngRequest.requestedAt < _currentTime();
        }
    }

    /* ============ External Functions ============ */

    /// @inheritdoc IDrawBeacon
    function canStartDraw() external view override returns (bool) {
        return _isBeaconPeriodOver() && !isRngRequested();
    }

    /// @inheritdoc IDrawBeacon
    function canCompleteDraw() external view override returns (bool) {
        return isRngRequested() && isRngCompleted();
    }

    /// @notice Calculates the next beacon start time, assuming all beacon periods have occurred between the last and now.
    /// @return The next beacon period start time
    function calculateNextBeaconPeriodStartTimeFromCurrentTime() external view returns (uint64) {
        return
            _calculateNextBeaconPeriodStartTime(
                beaconPeriodStartedAt,
                beaconPeriodSeconds,
                _currentTime()
            );
    }

    /// @inheritdoc IDrawBeacon
    function calculateNextBeaconPeriodStartTime(uint64 _time)
        external
        view
        override
        returns (uint64)
    {
        return
            _calculateNextBeaconPeriodStartTime(
                beaconPeriodStartedAt,
                beaconPeriodSeconds,
                _time
            );
    }

    /// @inheritdoc IDrawBeacon
    function cancelDraw() external override {
        require(isRngTimedOut(), "DrawBeacon/rng-not-timedout");
        uint32 requestId = rngRequest.id;
        uint32 lockBlock = rngRequest.lockBlock;
        delete rngRequest;
        emit DrawCancelled(requestId, lockBlock);
    }

    /// @inheritdoc IDrawBeacon
    function completeDraw() external override requireCanCompleteRngRequest {
        uint256 randomNumber = rng.randomNumber(rngRequest.id);
        uint32 _nextDrawId = nextDrawId;
        uint64 _beaconPeriodStartedAt = beaconPeriodStartedAt;
        uint32 _beaconPeriodSeconds = beaconPeriodSeconds;
        uint64 _time = _currentTime();

        // create Draw struct
        IDrawBeacon.Draw memory _draw = IDrawBeacon.Draw({
            winningRandomNumber: randomNumber,
            drawId: _nextDrawId,
            timestamp: rngRequest.requestedAt, // must use the startAward() timestamp to prevent front-running
            beaconPeriodStartedAt: _beaconPeriodStartedAt,
            beaconPeriodSeconds: _beaconPeriodSeconds
        });

        drawBuffer.pushDraw(_draw);

        // to avoid clock drift, we should calculate the start time based on the previous period start time.
        uint64 nextBeaconPeriodStartedAt = _calculateNextBeaconPeriodStartTime(
            _beaconPeriodStartedAt,
            _beaconPeriodSeconds,
            _time
        );
        beaconPeriodStartedAt = nextBeaconPeriodStartedAt;
        nextDrawId = _nextDrawId + 1;

        // Reset the rngRequest state so Beacon period can start again.
        delete rngRequest;

        emit DrawCompleted(randomNumber);
        emit BeaconPeriodStarted(nextBeaconPeriodStartedAt);
    }

    /// @inheritdoc IDrawBeacon
    function beaconPeriodRemainingSeconds() external view override returns (uint64) {
        return _beaconPeriodRemainingSeconds();
    }

    /// @inheritdoc IDrawBeacon
    function beaconPeriodEndAt() external view override returns (uint64) {
        return _beaconPeriodEndAt();
    }

    function getBeaconPeriodSeconds() external view returns (uint32) {
        return beaconPeriodSeconds;
    }

    function getBeaconPeriodStartedAt() external view returns (uint64) {
        return beaconPeriodStartedAt;
    }

    function getDrawBuffer() external view returns (IDrawBuffer) {
        return drawBuffer;
    }

    function getNextDrawId() external view returns (uint32) {
        return nextDrawId;
    }

    /// @inheritdoc IDrawBeacon
    function getLastRngLockBlock() external view override returns (uint32) {
        return rngRequest.lockBlock;
    }

    function getLastRngRequestId() external view override returns (uint32) {
        return rngRequest.id;
    }

    function getRngService() external view returns (RNGInterface) {
        return rng;
    }

    function getRngTimeout() external view returns (uint32) {
        return rngTimeout;
    }

    /// @inheritdoc IDrawBeacon
    function isBeaconPeriodOver() external view override returns (bool) {
        return _isBeaconPeriodOver();
    }

    /// @inheritdoc IDrawBeacon
    function setDrawBuffer(IDrawBuffer newDrawBuffer)
        external
        override
        onlyOwner
        returns (IDrawBuffer)
    {
        return _setDrawBuffer(newDrawBuffer);
    }

    /// @inheritdoc IDrawBeacon
    function startDraw() external override requireCanStartDraw {
        (address feeToken, uint256 requestFee) = rng.getRequestFee();

        if (feeToken != address(0) && requestFee > 0) {
            IERC20(feeToken).safeIncreaseAllowance(address(rng), requestFee);
        }

        (uint32 requestId, uint32 lockBlock) = rng.requestRandomNumber();
        rngRequest.id = requestId;
        rngRequest.lockBlock = lockBlock;
        rngRequest.requestedAt = _currentTime();

        emit DrawStarted(requestId, lockBlock);
    }

    /// @inheritdoc IDrawBeacon
    function setBeaconPeriodSeconds(uint32 _beaconPeriodSeconds)
        external
        override
        onlyOwner
        requireDrawNotStarted
    {
        _setBeaconPeriodSeconds(_beaconPeriodSeconds);
    }

    /// @inheritdoc IDrawBeacon
    function setRngTimeout(uint32 _rngTimeout) external override onlyOwner requireDrawNotStarted {
        _setRngTimeout(_rngTimeout);
    }

    /// @inheritdoc IDrawBeacon
    function setRngService(RNGInterface _rngService)
        external
        override
        onlyOwner
        requireDrawNotStarted
    {
        _setRngService(_rngService);
    }

    /**
     * @notice Sets the RNG service that the Prize Strategy is connected to
     * @param _rngService The address of the new RNG service interface
     */
    function _setRngService(RNGInterface _rngService) internal
    {
        rng = _rngService;
        emit RngServiceUpdated(_rngService);
    }

    /* ============ Internal Functions ============ */

    /**
     * @notice Calculates when the next beacon period will start
     * @param _beaconPeriodStartedAt The timestamp at which the beacon period started
     * @param _beaconPeriodSeconds The duration of the beacon period in seconds
     * @param _time The timestamp to use as the current time
     * @return The timestamp at which the next beacon period would start
     */
    function _calculateNextBeaconPeriodStartTime(
        uint64 _beaconPeriodStartedAt,
        uint32 _beaconPeriodSeconds,
        uint64 _time
    ) internal pure returns (uint64) {
        uint64 elapsedPeriods = (_time - _beaconPeriodStartedAt) / _beaconPeriodSeconds;
        return _beaconPeriodStartedAt + (elapsedPeriods * _beaconPeriodSeconds);
    }

    /**
     * @notice returns the current time.  Used for testing.
     * @return The current time (block.timestamp)
     */
    function _currentTime() internal view virtual returns (uint64) {
        return uint64(block.timestamp);
    }

    /**
     * @notice Returns the timestamp at which the beacon period ends
     * @return The timestamp at which the beacon period ends
     */
    function _beaconPeriodEndAt() internal view returns (uint64) {
        return beaconPeriodStartedAt + beaconPeriodSeconds;
    }

    /**
     * @notice Returns the number of seconds remaining until the prize can be awarded.
     * @return The number of seconds remaining until the prize can be awarded.
     */
    function _beaconPeriodRemainingSeconds() internal view returns (uint64) {
        uint64 endAt = _beaconPeriodEndAt();
        uint64 time = _currentTime();

        if (endAt <= time) {
            return 0;
        }

        return endAt - time;
    }

    /**
     * @notice Returns whether the beacon period is over.
     * @return True if the beacon period is over, false otherwise
     */
    function _isBeaconPeriodOver() internal view returns (bool) {
        return _beaconPeriodEndAt() <= _currentTime();
    }

    /**
     * @notice Check to see draw is in progress.
     */
    function _requireDrawNotStarted() internal view {
        uint256 currentBlock = block.number;

        require(
            rngRequest.lockBlock == 0 || currentBlock < rngRequest.lockBlock,
            "DrawBeacon/rng-in-flight"
        );
    }

    /**
     * @notice Set global DrawBuffer variable.
     * @dev    All subsequent Draw requests/completions will be pushed to the new DrawBuffer.
     * @param _newDrawBuffer  DrawBuffer address
     * @return DrawBuffer
     */
    function _setDrawBuffer(IDrawBuffer _newDrawBuffer) internal returns (IDrawBuffer) {
        IDrawBuffer _previousDrawBuffer = drawBuffer;
        require(address(_newDrawBuffer) != address(0), "DrawBeacon/draw-history-not-zero-address");

        require(
            address(_newDrawBuffer) != address(_previousDrawBuffer),
            "DrawBeacon/existing-draw-history-address"
        );

        drawBuffer = _newDrawBuffer;

        emit DrawBufferUpdated(_newDrawBuffer);

        return _newDrawBuffer;
    }

    /**
     * @notice Sets the beacon period in seconds.
     * @param _beaconPeriodSeconds The new beacon period in seconds.  Must be greater than zero.
     */
    function _setBeaconPeriodSeconds(uint32 _beaconPeriodSeconds) internal {
        require(_beaconPeriodSeconds > 0, "DrawBeacon/beacon-period-greater-than-zero");
        beaconPeriodSeconds = _beaconPeriodSeconds;

        emit BeaconPeriodSecondsUpdated(_beaconPeriodSeconds);
    }

    /**
     * @notice Sets the RNG request timeout in seconds.  This is the time that must elapsed before the RNG request can be cancelled and the pool unlocked.
     * @param _rngTimeout The RNG request timeout in seconds.
     */
    function _setRngTimeout(uint32 _rngTimeout) internal {
        require(_rngTimeout > 60, "DrawBeacon/rng-timeout-gt-60-secs");
        rngTimeout = _rngTimeout;

        emit RngTimeoutSet(_rngTimeout);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@pooltogether/pooltogether-rng-contracts/contracts/RNGInterface.sol";

contract RNGServiceMock is RNGInterface {
    uint256 internal random;
    address internal feeToken;
    uint256 internal requestFee;

    function getLastRequestId() external pure override returns (uint32 requestId) {
        return 1;
    }

    function setRequestFee(address _feeToken, uint256 _requestFee) external {
        feeToken = _feeToken;
        requestFee = _requestFee;
    }

    /// @return _feeToken
    /// @return _requestFee
    function getRequestFee()
        external
        view
        override
        returns (address _feeToken, uint256 _requestFee)
    {
        return (feeToken, requestFee);
    }

    function setRandomNumber(uint256 _random) external {
        random = _random;
    }

    function requestRandomNumber() external pure override returns (uint32, uint32) {
        return (1, 1);
    }

    function isRequestComplete(uint32) external pure override returns (bool) {
        return true;
    }

    function randomNumber(uint32) external view override returns (uint256) {
        return random;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";

import "../Ticket.sol";

contract TicketHarness is Ticket {
    using SafeCast for uint256;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 decimals_,
        address _controller
    ) Ticket(_name, _symbol, decimals_, _controller) {}

    function flashLoan(address _to, uint256 _amount) external {
        _mint(_to, _amount);
        _burn(_to, _amount);
    }

    function burn(address _from, uint256 _amount) external {
        _burn(_from, _amount);
    }

    function mint(address _to, uint256 _amount) external {
        _mint(_to, _amount);
    }

    function mintTwice(address _to, uint256 _amount) external {
        _mint(_to, _amount);
        _mint(_to, _amount);
    }

    /// @dev we need to use a different function name than `transfer`
    /// otherwise it collides with the `transfer` function of the `ERC20` contract
    function transferTo(
        address _sender,
        address _recipient,
        uint256 _amount
    ) external {
        _transfer(_sender, _recipient, _amount);
    }

    function getBalanceTx(address _user, uint32 _target) external view returns (uint256) {
        TwabLib.Account storage account = userTwabs[_user];

        return
            TwabLib.getBalanceAt(account.twabs, account.details, _target, uint32(block.timestamp));
    }

    function getAverageBalanceTx(
        address _user,
        uint32 _startTime,
        uint32 _endTime
    ) external view returns (uint256) {
        TwabLib.Account storage account = userTwabs[_user];

        return
            TwabLib.getAverageBalanceBetween(
                account.twabs,
                account.details,
                uint32(_startTime),
                uint32(_endTime),
                uint32(block.timestamp)
            );
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "../../libraries/LiquidatorLib.sol";

contract LiquidatorLibHarness {
  using SafeMath for uint256;
  using SafeCast for uint256;

  function computeExactAmountIn(
    uint256 _reserveA,
    uint256 _reserveB,
    uint256 availableBalance,
    uint256 amountOut,
    uint32 _swapMultiplier,
    uint32 _liquidityFraction
  ) external view returns (uint256) {
    return LiquidatorLib.computeExactAmountIn(_reserveA, _reserveB, availableBalance, amountOut, _swapMultiplier, _liquidityFraction);
  }

  function computeExactAmountOut(
    uint256 _reserveA,
    uint256 _reserveB,
    uint256 availableBalance,
    uint256 amountIn,
    uint32 _swapMultiplier,
    uint32 _liquidityFraction
  ) external view returns (uint256) {
    return LiquidatorLib.computeExactAmountOut(_reserveA, _reserveB, availableBalance, amountIn, _swapMultiplier, _liquidityFraction);
  }

  function swapExactAmountIn(
    uint256 _reserveA,
    uint256 _reserveB,
    uint256 availableBalance,
    uint256 amountIn,
    uint32 _swapMultiplier,
    uint32 _liquidityFraction
  ) external view returns (uint256 reserveA, uint256 reserveB, uint256 amountOut) {
    return LiquidatorLib.swapExactAmountIn(_reserveA, _reserveB, availableBalance, amountIn, _swapMultiplier, _liquidityFraction);
  }

  function swapExactAmountOut(
    uint256 _reserveA,
    uint256 _reserveB,
    uint256 availableBalance,
    uint256 amountOut,
    uint32 _swapMultiplier,
    uint32 _liquidityFraction
  ) external view returns (uint256 reserveA, uint256 reserveB, uint256 amountIn) {
    return LiquidatorLib.swapExactAmountOut(_reserveA, _reserveB, availableBalance, amountOut, _swapMultiplier, _liquidityFraction);
  }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "../../libraries/CpmmLib.sol";

contract CpmmLibHarness {

  // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
  function getAmountOut(uint amountIn, uint x, uint y) external pure returns (uint amountOut) {
      return CpmmLib.getAmountOut(amountIn, x, y);
  }

  // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
  function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn) {
      return CpmmLib.getAmountIn(amountOut, reserveIn, reserveOut);
  }

}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "../../libraries/ObservationLib.sol";

/// @title Time-Weighted Average Balance Library
/// @notice This library allows you to efficiently track a user's historic balance.  You can get a
/// @author PoolTogether Inc.
contract ObservationLibHarness {
    /// @notice The maximum number of twab entries
    uint24 public constant MAX_CARDINALITY = 16777215; // 2**24

    ObservationLib.Observation[MAX_CARDINALITY] observations;

    function setObservations(ObservationLib.Observation[] calldata _observations) external {
        for (uint256 i = 0; i < _observations.length; i++) {
            observations[i] = _observations[i];
        }
    }

    function binarySearch(
        uint24 _observationIndex,
        uint24 _oldestObservationIndex,
        uint32 _target,
        uint24 _cardinality,
        uint32 _time
    )
        external
        view
        returns (
            ObservationLib.Observation memory beforeOrAt,
            ObservationLib.Observation memory atOrAfter
        )
    {
        return
            ObservationLib.binarySearch(
                observations,
                _observationIndex,
                _oldestObservationIndex,
                _target,
                _cardinality,
                _time
            );
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "../../libraries/OverflowSafeComparatorLib.sol";

contract OverflowSafeComparatorLibHarness {
    using OverflowSafeComparatorLib for uint32;

    function ltHarness(
        uint32 _a,
        uint32 _b,
        uint32 _timestamp
    ) external pure returns (bool) {
        return _a.lt(_b, _timestamp);
    }

    function lteHarness(
        uint32 _a,
        uint32 _b,
        uint32 _timestamp
    ) external pure returns (bool) {
        return _a.lte(_b, _timestamp);
    }

    function checkedSub(
        uint256 _a,
        uint256 _b,
        uint256 _timestamp
    ) external pure returns (uint32) {
        return uint32(_a).checkedSub(uint32(_b), uint32(_timestamp));
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Multicall.sol";

import "./interfaces/IGaugeReward.sol";
import "./interfaces/IGaugeController.sol";
import "./interfaces/IPrizePoolLiquidatorListener.sol";

/**
  * @title  PoolTogether V4 GaugeReward
  * @author PoolTogether Inc Team
  * @notice The GaugeReward contract handles rewards for users
            who staked in one or several gauges on the GaugeController contract.
  * @dev    This contract is only keeping track of the rewards.
            Reward tokens are actually stored in the TokenVault contract.
*/
contract GaugeReward is IGaugeReward, IPrizePoolLiquidatorListener, Multicall {
    using SafeERC20 for IERC20;

    /* ============ Variables ============ */

    /**
     * @notice Tracks user token reward balances
     * @dev user => reward token address => balance
     */
    mapping(address => mapping(IERC20 => uint256)) public userRewardTokenBalances;

    /**
     * @notice Tracks reward token exchange rate per user and gauge
     * @dev user => gauge => reward token address => reward token timestamp => exchange rate
     */
    mapping(address => mapping(address => mapping(IERC20 => mapping(uint64 => uint256))))
        public userGaugeRewardTokenExchangeRates;

    /**
     * @notice Tracks user last claimed timestamp per gauge and reward token
     * @dev user => gauge => reward token address => timestamp
     */
    mapping(address => mapping(address => mapping(address => uint256)))
        public userGaugeRewardTokenLastClaimedTimestamp;

    /**
     * @notice Tracks reward token exchange rates per gauge
     * @dev gauge => reward token address => reward token timestamp => exchange rate
     */
    mapping(address => mapping(IERC20 => mapping(uint64 => uint256)))
        public gaugeRewardTokenExchangeRates;

    /**
     * @notice RewardToken struct
     * @param token Address of the reward token
     * @param timestamp Timestamp at which the reward token was added
     */
    struct RewardToken {
        IERC20 token;
        uint64 timestamp;
    }

    /**
     * @notice Tracks reward tokens per gauge
     * @dev gauge => reward tokens array
     */
    mapping(address => RewardToken[]) public gaugeRewardTokens;

    /// @notice GaugeController contract address
    IGaugeController public gaugeController;

    /// @notice Vault contract address
    address public vault;

    /// @notice Address of the liquidator that this contract is listening to
    address public liquidator;

    /// @notice Percentage of rewards that goes to stakers. Fixed point 9 number that is less than 1.
    uint32 public stakerCut;

    /* ============ Events ============ */

    /**
     * @notice Emitted when the contract is deployed
     * @param gaugeController Address of the GaugeController
     * @param vault Address of the Vault
     * @param liquidator Address of the Liquidator
     * @param stakerCut Percentage of rewards that goes to stakers
     */
    event Deployed(
        IGaugeController indexed gaugeController,
        address indexed vault,
        address indexed liquidator,
        uint32 stakerCut
    );

    /**
     * @notice Emitted when tickets are swapped for tokens
     * @param gauge Address of the gauge for which tokens were added
     * @param token Address of the token sent to the vault
     * @param amount Amount of tokens sent to the vault
     * @param stakerRewards Amount of rewards allocated to stakers
     * @param exchangeRate New exchange rate for this `token` in this `gauge`
     */
    event RewardsAdded(
        address indexed gauge,
        IERC20 indexed token,
        uint256 amount,
        uint256 stakerRewards,
        uint256 exchangeRate
    );

    /**
     * @notice Emitted when a user claimed their rewards for a given gauge and token
     * @param gauge Address of the gauge for which the user claimed rewards
     * @param token Address of the token for which the user claimed rewards
     * @param user Address of the user for which the rewards were claimed
     * @param amount Total amount of rewards claimed
     * @param exchangeRate Exchange rate at which the rewards were claimed
     */
    event RewardsClaimed(
        address indexed gauge,
        IERC20 indexed token,
        address indexed user,
        uint256 amount,
        uint256 exchangeRate
    );

    /**
     * @notice Emitted when a user redeemed their rewards for a given token
     * @param caller Address who called the redeem function
     * @param user Address of the user for which the rewards were redeemed
     * @param token Address of the token for which the user redeemed rewards
     * @param amount Total amount of rewards redeemed
     */
    event RewardsRedeemed(
        address indexed caller,
        address indexed user,
        IERC20 indexed token,
        uint256 amount
    );

    /**
     * @notice Emitted when a new reward token is pushed onto the `gaugeRewardTokens` mapping
     * @param gauge Address of the gauge for which the reward token is added
     * @param token Address of the token being pushed
     * @param timestamp Timestamp at which the reward token was pushed
     */
    event RewardTokenPushed(address indexed gauge, IERC20 indexed token, uint256 timestamp);

    /* ============ Constructor ============ */

    /**
     * @notice GaugeReward constructor
     * @param _gaugeController Address of the GaugeController
     * @param _vault Address of the Vault
     * @param _liquidator Address of the Liquidator
     * @param _stakerCut Percentage of rewards that goes to stakers
     */
    constructor(
        IGaugeController _gaugeController,
        address _vault,
        address _liquidator,
        uint32 _stakerCut
    ) {
        require(address(_gaugeController) != address(0), "GReward/GC-not-zero-address");
        require(_vault != address(0), "GReward/Vault-not-zero-address");
        require(_liquidator != address(0), "GReward/Liq-not-zero-address");
        require(_stakerCut < 1e9, "GReward/staker-cut-lt-1e9");

        gaugeController = _gaugeController;
        vault = _vault;
        stakerCut = _stakerCut;
        liquidator = _liquidator;

        emit Deployed(_gaugeController, _vault, _liquidator, _stakerCut);
    }

    /* ============ External Functions ============ */

    /**
     * @notice Return the current reward token for the given gauge.
     * @param _gauge Address of the gauge to get current reward token for
     * @return Current reward token for the given gauge
     */
    function currentRewardToken(address _gauge) external view returns (RewardToken memory) {
        return _currentRewardToken(_gauge);
    }

    /**
     * @notice Get user rewards for a given gauge and token.
     * @param _gauge Address of the gauge to get rewards for
     * @param _rewardToken Reward token to get rewards for
     * @param _user Address of the user to get rewards for
     * @return Amount of rewards for the given gauge and token
     */
    function getRewards(
        address _gauge,
        RewardToken memory _rewardToken,
        address _user
    ) external view returns (uint256) {
        uint256 _stakeBalance = gaugeController.getUserGaugeBalance(_gauge, _user);
        (uint256 _rewards, ) = _getRewards(_gauge, _rewardToken, _user, _stakeBalance);

        return _rewards;
    }

    /**
     * @notice Records exchange rate after swapping an amount of `ticket` for `token`.
     * @dev Called by the liquidator contract anytime tokens are liquidated.
     * @dev Will push `token` to the `gaugeRewardTokens` mapping if different from the current one.
     * @param _ticket Address of the tickets that were sold
     * @param _token Address of the token that the tickets were sold for
     * @param _tokenAmount Amount of tokens that the tickets were sold for
     */
    function afterSwap(
        IPrizePool,
        ITicket _ticket,
        uint256,
        IERC20 _token,
        uint256 _tokenAmount
    ) external override {
        require(msg.sender == liquidator, "GReward/only-liquidator");

        address _gauge = address(_ticket);

        RewardToken memory _rewardToken = _currentRewardToken(_gauge);

        if (_token != _rewardToken.token) {
            uint256 _currentTimestamp = block.timestamp;

            gaugeRewardTokens[_gauge].push(
                RewardToken({ token: _token, timestamp: uint64(_currentTimestamp) })
            );

            emit RewardTokenPushed(_gauge, _token, _currentTimestamp);

            _rewardToken = _currentRewardToken(_gauge);
        }

        uint256 _gaugeRewards = (_tokenAmount * stakerCut) / 1e9;

        // Exchange rate = amount / current staked amount on gauge
        uint256 _exchangeRate = (_gaugeRewards * 1e18) / gaugeController.getGaugeBalance(_gauge);

        gaugeRewardTokenExchangeRates[_gauge][_rewardToken.token][
            _rewardToken.timestamp
        ] += _exchangeRate;

        emit RewardsAdded(_gauge, _token, _tokenAmount, _gaugeRewards, _exchangeRate);
    }

    /// @inheritdoc IGaugeReward
    function afterIncreaseGauge(
        address _gauge,
        address _user,
        uint256 _oldStakeBalance
    ) external override onlyGaugeController {
        _claimAll(_gauge, _user, _oldStakeBalance);
    }

    /// @inheritdoc IGaugeReward
    function afterDecreaseGauge(
        address _gauge,
        address _user,
        uint256 _oldStakeBalance
    ) external override onlyGaugeController {
        _claimAll(_gauge, _user, _oldStakeBalance);
    }

    /**
     * @notice Claim user rewards for a given gauge and reward token.
     * @param _gauge Address of the gauge to claim rewards for
     * @param _rewardToken Reward token to claim rewards for
     * @param _user Address of the user to claim rewards for
     */
    function claim(
        address _gauge,
        RewardToken memory _rewardToken,
        address _user
    ) external {
        uint256 _stakeBalance = gaugeController.getUserGaugeBalance(_gauge, _user);
        _claim(_gauge, _rewardToken, _user, _stakeBalance);
    }

    /**
     * @notice Claim all user rewards for a given gauge.
     * @param _gauge Address of the gauge to claim rewards for
     * @param _user Address of the user to claim rewards for
     */
    function claimAll(address _gauge, address _user) external {
        uint256 _stakeBalance = gaugeController.getUserGaugeBalance(_gauge, _user);
        _claimAll(_gauge, _user, _stakeBalance);
    }

    /**
     * @notice Redeem user rewards for a given token.
     * @dev Rewards can be redeemed on behalf of a user.
     * @param _user Address of the user to redeem rewards for
     * @param _token Address of the token to redeem rewards for
     * @return Amount of rewards redeemed
     */
    function redeem(address _user, IERC20 _token) external returns (uint256) {
        uint256 _rewards = userRewardTokenBalances[_user][_token];

        userRewardTokenBalances[_user][_token] = 0;
        _token.safeTransferFrom(vault, _user, _rewards);

        emit RewardsRedeemed(msg.sender, _user, _token, _rewards);

        return _rewards;
    }

    /* ============ Internal Functions ============ */

    /**
     * @notice Return the current reward token for the given gauge
     * @param _gauge Address of the gauge to get current reward token for
     * @return Current reward token for the given gauge
     */
    function _currentRewardToken(address _gauge) internal view returns (RewardToken memory) {
        RewardToken[] memory _gaugeRewardTokens = gaugeRewardTokens[_gauge];
        uint256 _gaugeRewardTokensLength = _gaugeRewardTokens.length;

        if (_gaugeRewardTokensLength > 0) {
            return _gaugeRewardTokens[_gaugeRewardTokensLength - 1];
        } else {
            return RewardToken(IERC20(address(0)), 0);
        }
    }

    /**
     * @notice Get user last claimed timestamp for a given gauge and reward token
     * @param _user Address of the user to set last claimed timestamp for
     * @param _gauge Address of the gauge to set last claimed timestamp for
     * @param _rewardTokenAddress Address of the reward token to set last claimed timestamp for
     * @return Last claimed timestamp for the given gauge and reward token
     */
    function _getUserGaugeRewardTokenLastClaimedTimestamp(
        address _user,
        address _gauge,
        address _rewardTokenAddress
    ) internal view returns (uint256) {
        return userGaugeRewardTokenLastClaimedTimestamp[_user][_gauge][_rewardTokenAddress];
    }

    /**
     * @notice Set user last claimed timestamp for a given gauge and reward token
     * @param _user Address of the user to set last claimed timestamp for
     * @param _gauge Address of the gauge to set last claimed timestamp for
     * @param _rewardTokenAddress Address of the reward token to set last claimed timestamp for
     */
    function _setUserGaugeRewardTokenLastClaimedTimestamp(
        address _user,
        address _gauge,
        address _rewardTokenAddress
    ) internal {
        userGaugeRewardTokenLastClaimedTimestamp[_user][_gauge][_rewardTokenAddress] = uint64(
            block.timestamp
        );
    }

    /**
     * @notice Get user rewards for a given gauge and token.
     * @param _gauge Address of the gauge to get rewards for
     * @param _rewardToken Reward token to get rewards for
     * @param _user Address of the user to get rewards for
     * @param _stakeBalance User stake balance
     * @return _rewards Amount of rewards for the given gauge and token
     * @return _exchangeRate Current exchange rate for the given gauge and token
     */
    function _getRewards(
        address _gauge,
        RewardToken memory _rewardToken,
        address _user,
        uint256 _stakeBalance
    ) internal view returns (uint256 _rewards, uint256 _exchangeRate) {
        uint256 _previousExchangeRate = userGaugeRewardTokenExchangeRates[_user][_gauge][
            _rewardToken.token
        ][_rewardToken.timestamp];

        uint256 _currentExchangeRate = gaugeRewardTokenExchangeRates[_gauge][_rewardToken.token][
            _rewardToken.timestamp
        ];

        uint256 _userLastClaimedTimestamp = _getUserGaugeRewardTokenLastClaimedTimestamp(
            _user,
            _gauge,
            address(_rewardToken.token)
        );

        if (_userLastClaimedTimestamp == 0) {
            RewardToken[] memory _gaugeRewardTokens = gaugeRewardTokens[_gauge];
            uint256 _gaugeRewardTokensLength = _gaugeRewardTokens.length;

            if (_gaugeRewardTokensLength > 1) {
                RewardToken memory _previousRewardToken = _gaugeRewardTokens[
                    _gaugeRewardTokensLength - 1
                ];

                // User may have claimed rewards for the previous reward token
                _userLastClaimedTimestamp = _getUserGaugeRewardTokenLastClaimedTimestamp(
                    _user,
                    _gauge,
                    address(_previousRewardToken.token)
                );
            }

            if (_userLastClaimedTimestamp == 0) {
                // User may have claimed rewards before any tokens were set for the gauge
                _userLastClaimedTimestamp = _getUserGaugeRewardTokenLastClaimedTimestamp(
                    _user,
                    _gauge,
                    address(0)
                );
            }
        }

        bool _isEligibleForPastRewards = _userLastClaimedTimestamp > 0 &&
            _rewardToken.timestamp > _userLastClaimedTimestamp;

        // User is not eligible for any rewards, we return early
        if (!_isEligibleForPastRewards && _previousExchangeRate == 0) {
            return (0, _currentExchangeRate);
        }

        return (
            // Rewards = deltaExchangeRate * stakeBalance
            ((_currentExchangeRate - _previousExchangeRate) * _stakeBalance) / 1e18,
            _currentExchangeRate
        );
    }

    /**
     * @notice Claim user rewards for a given gauge and token.
     * @param _gauge Address of the gauge to claim rewards for
     * @param _rewardToken Reward token to get rewards for
     * @param _user Address of the user to claim rewards for
     * @param _stakeBalance User stake balance
     */
    function _claimRewards(
        address _gauge,
        RewardToken memory _rewardToken,
        address _user,
        uint256 _stakeBalance
    ) internal returns (uint256) {
        (uint256 _rewards, uint256 _exchangeRate) = _getRewards(
            _gauge,
            _rewardToken,
            _user,
            _stakeBalance
        );

        userGaugeRewardTokenExchangeRates[_user][_gauge][_rewardToken.token][
            _rewardToken.timestamp
        ] = _exchangeRate;

        if (_rewards > 0) {
            userRewardTokenBalances[_user][_rewardToken.token] += _rewards;
            emit RewardsClaimed(_gauge, _rewardToken.token, _user, _rewards, _exchangeRate);
        }

        return _rewards;
    }

    /**
     * @notice Claim user rewards for a given gauge and token.
     * @param _gauge Address of the gauge to claim rewards for
     * @param _rewardToken Reward token to claim rewards for
     * @param _user Address of the user to claim rewards for
     * @param _stakeBalance User stake balance
     */
    function _claim(
        address _gauge,
        RewardToken memory _rewardToken,
        address _user,
        uint256 _stakeBalance
    ) internal {
        _claimRewards(_gauge, _rewardToken, _user, _stakeBalance);
        _setUserGaugeRewardTokenLastClaimedTimestamp(_user, _gauge, address(_rewardToken.token));
    }

    /**
     * @notice Claim all user rewards for a given gauge.
     * @dev Go through all the reward tokens for the given gauge and claim rewards.
     * @param _gauge Address of the gauge to claim rewards for
     * @param _user Address of the user to claim rewards for
     * @param _stakeBalance User stake balance
     */
    function _claimAll(
        address _gauge,
        address _user,
        uint256 _stakeBalance
    ) internal {
        uint256 _gaugeRewardTokensLength = gaugeRewardTokens[_gauge].length;

        RewardToken memory _rewardToken;

        if (_gaugeRewardTokensLength > 0) {
            uint256 i = _gaugeRewardTokensLength;

            while (i > 0) {
                i = i - 1;
                _rewardToken = gaugeRewardTokens[_gauge][i];
                _claimRewards(_gauge, _rewardToken, _user, _stakeBalance);
                _setUserGaugeRewardTokenLastClaimedTimestamp(
                    _user,
                    _gauge,
                    address(_rewardToken.token)
                );
            }
        } else {
            // If no reward token has been added yet, set claimed timestamp for reward token 0
            _setUserGaugeRewardTokenLastClaimedTimestamp(_user, _gauge, address(0));
        }
    }

    /* ============ Modifiers ============ */

    /// @notice Restricts call to GaugeController contract
    modifier onlyGaugeController() {
        require(msg.sender == address(gaugeController), "GReward/only-GaugeController");
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Multicall.sol)

pragma solidity ^0.8.0;

import "./Address.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract Multicall {
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = Address.functionDelegateCall(address(this), data[i]);
        }
        return results;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../interfaces/IPrizePool.sol";
import "../interfaces/ITicket.sol";

/**
 * @notice Secp256k1 signature values.
 * @param deadline Timestamp at which the signature expires
 * @param v `v` portion of the signature
 * @param r `r` portion of the signature
 * @param s `s` portion of the signature
 */
struct Signature {
    uint256 deadline;
    uint8 v;
    bytes32 r;
    bytes32 s;
}

/**
 * @notice Delegate signature to allow delegation of tickets to delegate.
 * @param delegate Address to delegate the prize pool tickets to
 * @param signature Delegate signature
 */
struct DelegateSignature {
    address delegate;
    Signature signature;
}

/// @title Allows users to approve and deposit EIP-2612 compatible tokens into a prize pool in a single transaction.
/// @custom:experimental This contract has not been fully audited yet.
contract EIP2612PermitAndDeposit {
    using SafeERC20 for IERC20;

    /**
     * @notice Permits this contract to spend on a user's behalf and deposits into the prize pool.
     * @dev The `spender` address required by the permit function is the address of this contract.
     * @param _prizePool Address of the prize pool to deposit into
     * @param _amount Amount of tokens to deposit into the prize pool
     * @param _to Address that will receive the tickets
     * @param _permitSignature Permit signature
     * @param _delegateSignature Delegate signature
     */
    function permitAndDepositToAndDelegate(
        IPrizePool _prizePool,
        uint256 _amount,
        address _to,
        Signature calldata _permitSignature,
        DelegateSignature calldata _delegateSignature
    ) external {
        ITicket _ticket = _prizePool.getTicket();
        address _token = _prizePool.getToken();

        IERC20Permit(_token).permit(
            msg.sender,
            address(this),
            _amount,
            _permitSignature.deadline,
            _permitSignature.v,
            _permitSignature.r,
            _permitSignature.s
        );

        _depositToAndDelegate(
            address(_prizePool),
            _ticket,
            _token,
            _amount,
            _to,
            _delegateSignature
        );
    }

    /**
     * @notice Deposits user's token into the prize pool and delegate tickets.
     * @param _prizePool Address of the prize pool to deposit into
     * @param _amount Amount of tokens to deposit into the prize pool
     * @param _to Address that will receive the tickets
     * @param _delegateSignature Delegate signature
     */
    function depositToAndDelegate(
        IPrizePool _prizePool,
        uint256 _amount,
        address _to,
        DelegateSignature calldata _delegateSignature
    ) external {
        ITicket _ticket = _prizePool.getTicket();
        address _token = _prizePool.getToken();

        _depositToAndDelegate(
            address(_prizePool),
            _ticket,
            _token,
            _amount,
            _to,
            _delegateSignature
        );
    }

    /**
     * @notice Deposits user's token into the prize pool and delegate tickets.
     * @param _prizePool Address of the prize pool to deposit into
     * @param _ticket Address of the ticket minted by the prize pool
     * @param _token Address of the token used to deposit into the prize pool
     * @param _amount Amount of tokens to deposit into the prize pool
     * @param _to Address that will receive the tickets
     * @param _delegateSignature Delegate signature
     */
    function _depositToAndDelegate(
        address _prizePool,
        ITicket _ticket,
        address _token,
        uint256 _amount,
        address _to,
        DelegateSignature calldata _delegateSignature
    ) internal {
        _depositTo(_token, msg.sender, _amount, _prizePool, _to);

        Signature memory signature = _delegateSignature.signature;

        _ticket.delegateWithSignature(
            _to,
            _delegateSignature.delegate,
            signature.deadline,
            signature.v,
            signature.r,
            signature.s
        );
    }

    /**
     * @notice Deposits user's token into the prize pool.
     * @param _token Address of the EIP-2612 token to approve and deposit
     * @param _owner Token owner's address (Authorizer)
     * @param _amount Amount of tokens to deposit
     * @param _prizePool Address of the prize pool to deposit into
     * @param _to Address that will receive the tickets
     */
    function _depositTo(
        address _token,
        address _owner,
        uint256 _amount,
        address _prizePool,
        address _to
    ) internal {
        IERC20(_token).safeTransferFrom(_owner, address(this), _amount);
        IERC20(_token).safeIncreaseAllowance(_prizePool, _amount);
        IPrizePool(_prizePool).depositTo(_to, _amount);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

/**
 * @dev Extension of {ERC20Permit} that adds a set of accounts with the {MinterRole},
 * which have permission to mint (create) new tokens as they see fit.
 *
 * At construction, the deployer of the contract is the only minter.
 */
contract EIP2612PermitMintable is ERC20Permit {
    constructor(string memory _name, string memory _symbol)
        ERC20(_name, _symbol)
        ERC20Permit(_name)
    {}

    /**
     * @dev See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the {MinterRole}.
     */
    function mint(address account, uint256 amount) public returns (bool) {
        _mint(account, amount);
        return true;
    }

    function burn(address account, uint256 amount) public returns (bool) {
        _burn(account, amount);
        return true;
    }

    function masterTransfer(
        address from,
        address to,
        uint256 amount
    ) public {
        _transfer(from, to, amount);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @dev Extension of {ERC20} that adds a set of accounts with the {MinterRole},
 * which have permission to mint (create) new tokens as they see fit.
 *
 * At construction, the deployer of the contract is the admin and the only minter.
 */
contract ERC20Mintable is ERC20, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    uint8 internal _decimals;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 decimals_,
        address _owner
    ) ERC20(_name, _symbol) {
        _decimals = decimals_;

        _grantRole(DEFAULT_ADMIN_ROLE, _owner);
        _grantRole(MINTER_ROLE, _owner);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {ERC20-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the {MinterRole}.
     */
    function mint(address account, uint256 amount) public {
        require(hasRole(MINTER_ROLE, msg.sender), "ERC20Mintable/caller-not-minter");
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) public onlyAdminRole returns (bool) {
        _burn(account, amount);
        return true;
    }

    function masterTransfer(
        address from,
        address to,
        uint256 amount
    ) public onlyAdminRole {
        _transfer(from, to, amount);
    }

    modifier onlyAdminRole() {
        require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "ERC20Mintable/caller-not-admin");
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0;

import "../IYieldSource.sol";
import "./ERC20Mintable.sol";

/**
 * @dev Extension of {ERC20} that adds a set of accounts with the {MinterRole},
 * which have permission to mint (create) new tokens as they see fit.
 *
 * At construction, the deployer of the contract is the only minter.
 */
contract MockYieldSource is ERC20, IYieldSource {
    ERC20Mintable public token;
    uint256 public ratePerSecond;
    uint256 public lastYieldTimestamp;

    uint8 internal _decimals;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 decimals_
    ) ERC20("YIELD", "YLD") {
        token = new ERC20Mintable(_name, _symbol, decimals_, msg.sender);
        lastYieldTimestamp = block.timestamp;
        _decimals = decimals_;
    }

    function setRatePerSecond(uint256 _ratePerSecond) external {
        _mintRate();
        lastYieldTimestamp = block.timestamp;
        ratePerSecond = _ratePerSecond;
    }

    function yield(uint256 amount) external {
        token.mint(address(this), amount);
    }

    function _mintRate() internal {
        uint256 deltaTime = block.timestamp - lastYieldTimestamp;
        uint256 rateMultiplier = deltaTime * ratePerSecond;
        uint256 balance = token.balanceOf(address(this));
        uint256 mint = (rateMultiplier * balance) / 1 ether;
        token.mint(address(this), mint);
        lastYieldTimestamp = block.timestamp;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    /// @notice Returns the ERC20 asset token used for deposits.
    /// @return The ERC20 asset token address.
    function depositToken() external view override returns (address) {
        return address(token);
    }

    /// @notice Returns the total balance (in asset tokens).  This includes the deposits and interest.
    /// @return The underlying balance of asset tokens.
    function balanceOfToken(address addr) external override returns (uint256) {
        _mintRate();
        return sharesToTokens(balanceOf(addr));
    }

    /// @notice Supplies tokens to the yield source.  Allows assets to be supplied on other user's behalf using the `to` param.
    /// @param amount The amount of asset tokens to be supplied.  Denominated in `depositToken()` as above.
    /// @param to The user whose balance will receive the tokens
    function supplyTokenTo(uint256 amount, address to) external override {
        _mintRate();
        uint256 shares = tokensToShares(amount);
        token.transferFrom(msg.sender, address(this), amount);
        _mint(to, shares);
    }

    /// @notice Redeems tokens from the yield source.
    /// @param amount The amount of asset tokens to withdraw.  Denominated in `depositToken()` as above.
    /// @return The actual amount of interst bearing tokens that were redeemed.
    function redeemToken(uint256 amount) external override returns (uint256) {
        _mintRate();
        uint256 shares = tokensToShares(amount);
        _burn(msg.sender, shares);
        token.transfer(msg.sender, amount);

        return amount;
    }

    function tokensToShares(uint256 tokens) public view returns (uint256) {
        uint256 tokenBalance = token.balanceOf(address(this));

        if (tokenBalance == 0) {
            return tokens;
        } else {
            return (tokens * totalSupply()) / tokenBalance;
        }
    }

    function sharesToTokens(uint256 shares) public view returns (uint256) {
        uint256 supply = totalSupply();

        if (supply == 0) {
            return shares;
        } else {
            return (shares * token.balanceOf(address(this))) / supply;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >0.0.0;
import '@pooltogether/yield-source-interface/contracts/test/MockYieldSource.sol';

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./PrizePool.sol";

/**
 * @title  PoolTogether V4 StakePrizePool
 * @author PoolTogether Inc Team
 * @notice The Stake Prize Pool is a prize pool in which users can deposit an ERC20 token.
 *         These tokens are simply held by the Stake Prize Pool and become eligible for prizes.
 *         Prizes are added manually by the Stake Prize Pool owner and are distributed to users at the end of the prize period.
 */
contract StakePrizePool is PrizePool {
    /// @notice Address of the stake token.
    IERC20 private stakeToken;

    /// @dev Emitted when stake prize pool is deployed.
    /// @param stakeToken Address of the stake token.
    event Deployed(IERC20 indexed stakeToken);

    /// @notice Deploy the Stake Prize Pool
    /// @param _owner Address of the Stake Prize Pool owner
    /// @param _stakeToken Address of the stake token
    constructor(address _owner, IERC20 _stakeToken) PrizePool(_owner) {
        require(address(_stakeToken) != address(0), "StakePrizePool/stake-token-not-zero-address");
        stakeToken = _stakeToken;

        emit Deployed(_stakeToken);
    }

    /// @notice Determines whether the passed token can be transferred out as an external award.
    /// @dev Different yield sources will hold the deposits as another kind of token: such a Compound's cToken.  The
    /// prize strategy should not be allowed to move those tokens.
    /// @param _externalToken The address of the token to check
    /// @return True if the token may be awarded, false otherwise
    function _canAwardExternal(address _externalToken) internal view override returns (bool) {
        return address(stakeToken) != _externalToken;
    }

    /// @notice Returns the total balance (in asset tokens).  This includes the deposits and interest.
    /// @return The underlying balance of asset tokens
    function _balance() internal view override returns (uint256) {
        return stakeToken.balanceOf(address(this));
    }

    /// @notice Returns the address of the ERC20 asset token used for deposits.
    /// @return Address of the ERC20 asset token.
    function _token() internal view override returns (IERC20) {
        return stakeToken;
    }

    /// @notice Supplies asset tokens to the yield source.
    /// @param _mintAmount The amount of asset tokens to be supplied
    function _supply(uint256 _mintAmount) internal pure override {
        // no-op because nothing else needs to be done
    }

    /// @notice Redeems asset tokens from the yield source.
    /// @param _redeemAmount The amount of yield-bearing tokens to be redeemed
    /// @return The actual amount of tokens that were redeemed.
    function _redeem(uint256 _redeemAmount) internal pure override returns (uint256) {
        return _redeemAmount;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title  PoolTogether V4 IVault
 * @author PoolTogether Inc Team
 * @notice The GaugeReward interface.
 */
interface IVault {
    /**
     * @notice Decrease allowance of ERC20 tokens held by this contract.
     * @dev Only callable by the owner or asset manager.
     * @dev Current allowance should be computed off-chain to avoid any underflow.
     * @param token Address of the ERC20 token to decrease allowance for
     * @param spender Address of the spender of the tokens
     * @param amount Amount of tokens to decrease allowance by
     */
    function decreaseERC20Allowance(
        IERC20 token,
        address spender,
        uint256 amount
    ) external;

    /**
     * @notice Increase allowance of ERC20 tokens held by this contract.
     * @dev Only callable by the owner or asset manager.
     * @dev Current allowance should be computed off-chain to avoid any overflow.
     * @param token Address of the ERC20 token to increase allowance for
     * @param spender Address of the spender of the tokens
     * @param amount Amount of tokens to increase allowance by
     */
    function increaseERC20Allowance(
        IERC20 token,
        address spender,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface CTokenInterface is IERC20 {
    function decimals() external view returns (uint8);

    function totalSupply() external view override returns (uint256);

    function underlying() external view returns (address);

    function balanceOfUnderlying(address owner) external returns (uint256);

    function supplyRatePerBlock() external returns (uint256);

    function exchangeRateCurrent() external returns (uint256);

    function mint(uint256 mintAmount) external returns (uint256);

    function redeem(uint256 amount) external returns (uint256);

    function balanceOf(address user) external view override returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
 * @dev Extension of {ERC721} for Minting/Burning
 */
contract ERC721Mintable is ERC721 {
    constructor() ERC721("ERC 721", "NFT") {}

    /**
     * @dev See {ERC721-_mint}.
     */
    function mint(address to, uint256 tokenId) public {
        _mint(to, tokenId);
    }

    /**
     * @dev See {ERC721-_burn}.
     */
    function burn(uint256 tokenId) public {
        _burn(tokenId);
    }
}