// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./extensions/ERC777Security.sol";

/**
 * @title SOMA Security Token Contract.
 * @author SOMA.finance.
 * @notice Security Token Contract.
 */
contract SecurityToken is ERC777Security {

    /**
     * @notice Initializer of the token contract.
     * @param domain The domain of the token.
     * @param name The name of the token.
     * @param symbol The symbol of the token.
     * @param defaultOperators The array of default operators for the token.
     */
    function initialize(string memory domain, string memory name, string memory symbol, address[] memory defaultOperators) external initializer virtual {
        __ERC777Security_init(domain, name, symbol, defaultOperators);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC777/ERC777Upgradeable.sol";

import "./ERC777Guard.sol";
import "./SeizableSecurity.sol";
import "./MintableSecurity.sol";
import "./ERC777VotesUpgradeable.sol";
import "./ERC777PausableUpgradeable.sol";

/**
 * @notice Abstract ERC777Security contract.
 */
abstract contract ERC777Security is ERC777PausableUpgradeable, ERC777VotesUpgradeable, MintableSecurity, SeizableSecurity, ERC777Guard {

    /**
     * @notice Initializer for extended contracts.
     * @param domain The domain of the token.
     * @param name The name of the token.
     * @param symbol The symbol of the token.
     * @param name The array of default operators.
     */
    function __ERC777Security_init(string memory domain, string memory name, string memory symbol, address[] memory defaultOperators) internal onlyInitializing {
        __ERC777Permit_init(domain);
        __ERC777Votes_init_unchained();
        __ERC165_init_unchained();
        __Context_init_unchained();
        __Guardable__init_unchained();
        __SomaContract_init_unchained();
        __Accessible_init_unchained();
        __SeizableSecurity_init_unchained();
        __MintableSecurity_init_unchained();
        __ERC777_init_unchained(name, symbol, defaultOperators);
        __ERC777Pausable_init_unchained();
    }

    /**
     * @notice Unchained initializer.
     */
    function __ERC777Security_init_unchained() internal onlyInitializing {
    }

    /**
     * @notice Returns a boolean indicating if the contract is paused.
     */
    function paused() public view virtual override(PausableUpgradeable, SomaContractUpgradeable) returns (bool) {
        return super.paused();
    }

    /**
     * @notice Checks if ERC777Security inherits a given contract interface.
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC777Guard, SeizableSecurity, MintableSecurity) returns (bool) {
        return interfaceId == type(IERC20Upgradeable).interfaceId ||
          interfaceId == type(IERC777Upgradeable).interfaceId ||
          super.supportsInterface(interfaceId);
    }

    function _mint(address to, uint256 amount, bytes memory userData, bytes memory operatorData) internal override(ERC777Upgradeable, ERC777VotesUpgradeable, MintableSecurity) {
        super._mint(to, amount, userData, operatorData);
    }

    function _burn(address to, uint256 amount, bytes memory userData, bytes memory operatorData) internal override(ERC777Upgradeable, ERC777VotesUpgradeable) {
        super._burn(to, amount, userData, operatorData);
    }

    function _seize(address from, address to, uint256 amount, bytes memory userData, bytes memory operatorData) internal override {
        _send(from, to, amount, userData, operatorData, false);
    }

    function _beforeTokenTransfer(
        address operator, 
        address from, 
        address to, 
        uint256 amount
    ) internal virtual override(ERC777VotesUpgradeable, ERC777PausableUpgradeable, ERC777Guard) {
        super._beforeTokenTransfer(operator, from, to, amount);
    }

    function _bypassValidate() internal virtual override returns (bool) {
        return (seizeInProgress) ? true : false;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC777/ERC777.sol)

pragma solidity ^0.8.0;

import "./IERC777Upgradeable.sol";
import "./IERC777RecipientUpgradeable.sol";
import "./IERC777SenderUpgradeable.sol";
import "../ERC20/IERC20Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/introspection/IERC1820RegistryUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC777} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 *
 * Support for ERC20 is included in this contract, as specified by the EIP: both
 * the ERC777 and ERC20 interfaces can be safely used when interacting with it.
 * Both {IERC777-Sent} and {IERC20-Transfer} events are emitted on token
 * movements.
 *
 * Additionally, the {IERC777-granularity} value is hard-coded to `1`, meaning that there
 * are no special restrictions in the amount of tokens that created, moved, or
 * destroyed. This makes integration with ERC20 applications seamless.
 */
contract ERC777Upgradeable is Initializable, ContextUpgradeable, IERC777Upgradeable, IERC20Upgradeable {
    using AddressUpgradeable for address;

    IERC1820RegistryUpgradeable internal constant _ERC1820_REGISTRY = IERC1820RegistryUpgradeable(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    mapping(address => uint256) private _balances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    bytes32 private constant _TOKENS_SENDER_INTERFACE_HASH = keccak256("ERC777TokensSender");
    bytes32 private constant _TOKENS_RECIPIENT_INTERFACE_HASH = keccak256("ERC777TokensRecipient");

    // This isn't ever read from - it's only used to respond to the defaultOperators query.
    address[] private _defaultOperatorsArray;

    // Immutable, but accounts may revoke them (tracked in __revokedDefaultOperators).
    mapping(address => bool) private _defaultOperators;

    // For each account, a mapping of its operators and revoked default operators.
    mapping(address => mapping(address => bool)) private _operators;
    mapping(address => mapping(address => bool)) private _revokedDefaultOperators;

    // ERC20-allowances
    mapping(address => mapping(address => uint256)) private _allowances;

    /**
     * @dev `defaultOperators` may be an empty array.
     */
    function __ERC777_init(
        string memory name_,
        string memory symbol_,
        address[] memory defaultOperators_
    ) internal onlyInitializing {
        __ERC777_init_unchained(name_, symbol_, defaultOperators_);
    }

    function __ERC777_init_unchained(
        string memory name_,
        string memory symbol_,
        address[] memory defaultOperators_
    ) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;

        _defaultOperatorsArray = defaultOperators_;
        for (uint256 i = 0; i < defaultOperators_.length; i++) {
            _defaultOperators[defaultOperators_[i]] = true;
        }

        // register interfaces
        _ERC1820_REGISTRY.setInterfaceImplementer(address(this), keccak256("ERC777Token"), address(this));
        _ERC1820_REGISTRY.setInterfaceImplementer(address(this), keccak256("ERC20Token"), address(this));
    }

    /**
     * @dev See {IERC777-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC777-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {ERC20-decimals}.
     *
     * Always returns 18, as per the
     * [ERC777 EIP](https://eips.ethereum.org/EIPS/eip-777#backward-compatibility).
     */
    function decimals() public pure virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC777-granularity}.
     *
     * This implementation always returns `1`.
     */
    function granularity() public view virtual override returns (uint256) {
        return 1;
    }

    /**
     * @dev See {IERC777-totalSupply}.
     */
    function totalSupply() public view virtual override(IERC20Upgradeable, IERC777Upgradeable) returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Returns the amount of tokens owned by an account (`tokenHolder`).
     */
    function balanceOf(address tokenHolder) public view virtual override(IERC20Upgradeable, IERC777Upgradeable) returns (uint256) {
        return _balances[tokenHolder];
    }

    /**
     * @dev See {IERC777-send}.
     *
     * Also emits a {IERC20-Transfer} event for ERC20 compatibility.
     */
    function send(
        address recipient,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        _send(_msgSender(), recipient, amount, data, "", true);
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Unlike `send`, `recipient` is _not_ required to implement the {IERC777Recipient}
     * interface if it is a contract.
     *
     * Also emits a {Sent} event.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _send(_msgSender(), recipient, amount, "", "", false);
        return true;
    }

    /**
     * @dev See {IERC777-burn}.
     *
     * Also emits a {IERC20-Transfer} event for ERC20 compatibility.
     */
    function burn(uint256 amount, bytes memory data) public virtual override {
        _burn(_msgSender(), amount, data, "");
    }

    /**
     * @dev See {IERC777-isOperatorFor}.
     */
    function isOperatorFor(address operator, address tokenHolder) public view virtual override returns (bool) {
        return
            operator == tokenHolder ||
            (_defaultOperators[operator] && !_revokedDefaultOperators[tokenHolder][operator]) ||
            _operators[tokenHolder][operator];
    }

    /**
     * @dev See {IERC777-authorizeOperator}.
     */
    function authorizeOperator(address operator) public virtual override {
        require(_msgSender() != operator, "ERC777: authorizing self as operator");

        if (_defaultOperators[operator]) {
            delete _revokedDefaultOperators[_msgSender()][operator];
        } else {
            _operators[_msgSender()][operator] = true;
        }

        emit AuthorizedOperator(operator, _msgSender());
    }

    /**
     * @dev See {IERC777-revokeOperator}.
     */
    function revokeOperator(address operator) public virtual override {
        require(operator != _msgSender(), "ERC777: revoking self as operator");

        if (_defaultOperators[operator]) {
            _revokedDefaultOperators[_msgSender()][operator] = true;
        } else {
            delete _operators[_msgSender()][operator];
        }

        emit RevokedOperator(operator, _msgSender());
    }

    /**
     * @dev See {IERC777-defaultOperators}.
     */
    function defaultOperators() public view virtual override returns (address[] memory) {
        return _defaultOperatorsArray;
    }

    /**
     * @dev See {IERC777-operatorSend}.
     *
     * Emits {Sent} and {IERC20-Transfer} events.
     */
    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes memory data,
        bytes memory operatorData
    ) public virtual override {
        require(isOperatorFor(_msgSender(), sender), "ERC777: caller is not an operator for holder");
        _send(sender, recipient, amount, data, operatorData, true);
    }

    /**
     * @dev See {IERC777-operatorBurn}.
     *
     * Emits {Burned} and {IERC20-Transfer} events.
     */
    function operatorBurn(
        address account,
        uint256 amount,
        bytes memory data,
        bytes memory operatorData
    ) public virtual override {
        require(isOperatorFor(_msgSender(), account), "ERC777: caller is not an operator for holder");
        _burn(account, amount, data, operatorData);
    }

    /**
     * @dev See {IERC20-allowance}.
     *
     * Note that operator and allowance concepts are orthogonal: operators may
     * not have allowance, and accounts with allowance may not be operators
     * themselves.
     */
    function allowance(address holder, address spender) public view virtual override returns (uint256) {
        return _allowances[holder][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `value` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Note that accounts cannot have allowance issued by their operators.
     */
    function approve(address spender, uint256 value) public virtual override returns (bool) {
        address holder = _msgSender();
        _approve(holder, spender, value);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Note that operator and allowance concepts are orthogonal: operators cannot
     * call `transferFrom` (unless they have allowance), and accounts with
     * allowance cannot call `operatorSend` (unless they are operators).
     *
     * Emits {Sent}, {IERC20-Transfer} and {IERC20-Approval} events.
     */
    function transferFrom(
        address holder,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(holder, spender, amount);
        _send(holder, recipient, amount, "", "", false);
        return true;
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * If a send hook is registered for `account`, the corresponding function
     * will be called with the caller address as the `operator` and with
     * `userData` and `operatorData`.
     *
     * See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits {Minted} and {IERC20-Transfer} events.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - if `account` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function _mint(
        address account,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData
    ) internal virtual {
        _mint(account, amount, userData, operatorData, true);
    }

    /**
     * @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * If `requireReceptionAck` is set to true, and if a send hook is
     * registered for `account`, the corresponding function will be called with
     * `operator`, `data` and `operatorData`.
     *
     * See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits {Minted} and {IERC20-Transfer} events.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - if `account` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function _mint(
        address account,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData,
        bool requireReceptionAck
    ) internal virtual {
        require(account != address(0), "ERC777: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, amount);

        // Update state variables
        _totalSupply += amount;
        _balances[account] += amount;

        _callTokensReceived(operator, address(0), account, amount, userData, operatorData, requireReceptionAck);

        emit Minted(operator, account, amount, userData, operatorData);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Send tokens
     * @param from address token holder address
     * @param to address recipient address
     * @param amount uint256 amount of tokens to transfer
     * @param userData bytes extra information provided by the token holder (if any)
     * @param operatorData bytes extra information provided by the operator (if any)
     * @param requireReceptionAck if true, contract recipients are required to implement ERC777TokensRecipient
     */
    function _send(
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData,
        bool requireReceptionAck
    ) internal virtual {
        require(from != address(0), "ERC777: transfer from the zero address");
        require(to != address(0), "ERC777: transfer to the zero address");

        address operator = _msgSender();

        _callTokensToSend(operator, from, to, amount, userData, operatorData);

        _move(operator, from, to, amount, userData, operatorData);

        _callTokensReceived(operator, from, to, amount, userData, operatorData, requireReceptionAck);
    }

    /**
     * @dev Burn tokens
     * @param from address token holder address
     * @param amount uint256 amount of tokens to burn
     * @param data bytes extra information provided by the token holder
     * @param operatorData bytes extra information provided by the operator (if any)
     */
    function _burn(
        address from,
        uint256 amount,
        bytes memory data,
        bytes memory operatorData
    ) internal virtual {
        require(from != address(0), "ERC777: burn from the zero address");

        address operator = _msgSender();

        _callTokensToSend(operator, from, address(0), amount, data, operatorData);

        _beforeTokenTransfer(operator, from, address(0), amount);

        // Update state variables
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC777: burn amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _totalSupply -= amount;

        emit Burned(operator, from, amount, data, operatorData);
        emit Transfer(from, address(0), amount);
    }

    function _move(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData
    ) private {
        _beforeTokenTransfer(operator, from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC777: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Sent(operator, from, to, amount, userData, operatorData);
        emit Transfer(from, to, amount);
    }

    /**
     * @dev See {ERC20-_approve}.
     *
     * Note that accounts cannot have allowance issued by their operators.
     */
    function _approve(
        address holder,
        address spender,
        uint256 value
    ) internal virtual {
        require(holder != address(0), "ERC777: approve from the zero address");
        require(spender != address(0), "ERC777: approve to the zero address");

        _allowances[holder][spender] = value;
        emit Approval(holder, spender, value);
    }

    /**
     * @dev Call from.tokensToSend() if the interface is registered
     * @param operator address operator requesting the transfer
     * @param from address token holder address
     * @param to address recipient address
     * @param amount uint256 amount of tokens to transfer
     * @param userData bytes extra information provided by the token holder (if any)
     * @param operatorData bytes extra information provided by the operator (if any)
     */
    function _callTokensToSend(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData
    ) private {
        address implementer = _ERC1820_REGISTRY.getInterfaceImplementer(from, _TOKENS_SENDER_INTERFACE_HASH);
        if (implementer != address(0)) {
            IERC777SenderUpgradeable(implementer).tokensToSend(operator, from, to, amount, userData, operatorData);
        }
    }

    /**
     * @dev Call to.tokensReceived() if the interface is registered. Reverts if the recipient is a contract but
     * tokensReceived() was not registered for the recipient
     * @param operator address operator requesting the transfer
     * @param from address token holder address
     * @param to address recipient address
     * @param amount uint256 amount of tokens to transfer
     * @param userData bytes extra information provided by the token holder (if any)
     * @param operatorData bytes extra information provided by the operator (if any)
     * @param requireReceptionAck if true, contract recipients are required to implement ERC777TokensRecipient
     */
    function _callTokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData,
        bool requireReceptionAck
    ) private {
        address implementer = _ERC1820_REGISTRY.getInterfaceImplementer(to, _TOKENS_RECIPIENT_INTERFACE_HASH);
        if (implementer != address(0)) {
            IERC777RecipientUpgradeable(implementer).tokensReceived(operator, from, to, amount, userData, operatorData);
        } else if (requireReceptionAck) {
            require(!to.isContract(), "ERC777: token recipient contract has no implementer for ERC777TokensRecipient");
        }
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
            require(currentAllowance >= amount, "ERC777: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes
     * calls to {send}, {transfer}, {operatorSend}, minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[41] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC777/ERC777Upgradeable.sol";

import "../../SomaGuard/utils/GuardableUpgradeable.sol";

import "./IERC777Guard.sol";

/**
 * @notice Implementation of the {IERC777Guard} interface.
 */
abstract contract ERC777Guard is IERC777Guard, ERC777Upgradeable, GuardableUpgradeable {

    /**
     * @notice Initializer for extended contracts.
     */
    function __ERC777Guard_init() internal {
        __ERC165_init_unchained();
        __Context_init_unchained();
        __Guardable__init_unchained();
        __SomaContract_init_unchained();
        __Accessible_init_unchained();
    }

    /**
     * @notice Checks that both `from` and `to` have the required privileges.
     * @param _from The address sending the tokens.
     * @param _to The address receiving the tokens.
     * @return True if the transfer is valid.
     */
    function canTransferFrom(address _from, address _to, uint256) public virtual view returns (bool) {
        ISomaGuard _guard = ISomaGuard(SOMA.guard());
        bytes32 _privileges = requiredPrivileges();

        // if the from address is 0 then it is minting
        // if the to address is 0 then it is burning
        // in both scenarios, we want to assume that address(0) is allowed.
        return  (_from == address(0)    || _guard.check(_from, _privileges)) &&
                (_to == address(0)      || _guard.check(_to, _privileges));
    }

    /**
     * @notice Checks if ERC777Guard inherits a given contract interface.
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC777Guard).interfaceId ||
                super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, amount);

        // ignore checks if bypass is true
        if (_bypassValidate()) return;

        // SomaGuard check, for determining if each user has the requiredPrivileges for this security
        require(canTransferFrom(from, to, amount), 'ERC777Guard: MISSING_PRIVILEGES');

    }

    function _bypassValidate() internal virtual returns (bool) {
        return false;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../../SomaAccessControl/utils/AccessibleUpgradeable.sol";

import "./ISeizableSecurity.sol";

/**
 * @notice Implementation of the {ISeizableSecurity} interface.
 */
abstract contract SeizableSecurity is ISeizableSecurity, AccessibleUpgradeable {

    /**
     * @notice Initializer for extended contracts.
     */
    function __SeizableSecurity_init() internal {
        __ERC165_init_unchained();
        __SeizableSecurity_init_unchained();
        __SomaContract_init_unchained();
        __Accessible_init_unchained();
    }

    /**
     * @notice Unchained initializer.
     */
    function __SeizableSecurity_init_unchained() internal onlyInitializing {
        LOCAL_SEIZE_ROLE = keccak256(abi.encodePacked(address(this), GLOBAL_SEIZE_ROLE));
    }

    /**
     * @notice Returns the GLOBAL_SEIZE_ROLE.
     */
    bytes32 public constant GLOBAL_SEIZE_ROLE = keccak256('SeizableSecurity.SEIZE_ROLE');

    /**
     * @notice Returns the LOCAL_SEIZE_ROLE.
     */
    bytes32 public LOCAL_SEIZE_ROLE;

    /**
     * @notice True if a seize is in progress, else False.
     */
    bool internal seizeInProgress;

    /**
     * @notice Modifier to update seize in progress state.
     */
    modifier enableSeizing {
        seizeInProgress = true;
        _;
        seizeInProgress = false;
    }

    /**
     * @notice Modifier to restrict a function caller to an account with the GLOBAL_SEIZE_ROLE or LOCAL_SEIZE_ROLE.
     */
    modifier onlySeizeRole {
        address sender = _msgSender();
        require(
            hasRole(LOCAL_SEIZE_ROLE, sender) || hasRole(GLOBAL_SEIZE_ROLE, sender),
            'SeizableSecurity: UNAUTHORIZED'
        );
        _;
    }

    /**
     * @notice Checks if SeizableSecurity inherits a given contract interface.
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(ISeizableSecurity).interfaceId ||
                super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc ISeizableSecurity
     */
    function seize(address tokenHolder, uint256 amount) external override {
        seize(tokenHolder, amount, "", "");
    }

    /**
     * @inheritdoc ISeizableSecurity
     */
    function seize(address tokenHolder, uint256 amount, bytes memory userData, bytes memory operatorData)
    public
    override
    enableSeizing
    onlySeizeRole {
        address seizeTo = SOMA.seizeTo();
        _seize(tokenHolder, seizeTo, amount, userData, operatorData);
        emit Seized(_msgSender(), tokenHolder, seizeTo, amount, userData, operatorData);
    }

    function _seize(address from, address to, uint256 amount, bytes memory userData, bytes memory operatorData) internal virtual;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../../SomaGuard/utils/GuardableUpgradeable.sol";

import "./IMintableSecurity.sol";

/**
 * @notice Implementation of the {IMintableSecurity} interface.
 */
abstract contract MintableSecurity is IMintableSecurity, AccessibleUpgradeable {

    /**
     * @notice Initializer for extended contracts.
     */
    function __MintableSecurity_init() internal {
        __Accessible_init();
        __MintableSecurity_init_unchained();
    }

    /**
     * @notice Unchained initializer.
     */
    function __MintableSecurity_init_unchained() internal onlyInitializing {
        LOCAL_MINT_ROLE = keccak256(abi.encodePacked(address(this), GLOBAL_MINT_ROLE));
    }

    /**
     * @notice Returns the GLOBAL_MINT_ROLE.
     */
    bytes32 public constant GLOBAL_MINT_ROLE = keccak256('MintableSecurity.MINT_ROLE');

    /**
     * @notice Returns the LOCAL_MINT_ROLE.
     */
    bytes32 public LOCAL_MINT_ROLE;

    /**
     * @notice Modifier to restrict a function caller to accounts that have the GLOBAL_ADMIN_ROLE or LOCAL_ADMIN_ROLE.
     */
    modifier onlyMintRole {
        address sender = _msgSender();
        require(
            hasRole(LOCAL_MINT_ROLE, sender) || hasRole(GLOBAL_MINT_ROLE, sender),
            'MintableSecurity: UNAUTHORIZED'
        );
        _;
    }

    /**
     * @notice Checks if MintableSecurity inherits a given contract interface.
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IMintableSecurity).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IMintableSecurity
     */
    function mint(uint256 amount) external override {
        mint(amount, "", "");
    }

    /**
     * @inheritdoc IMintableSecurity
     */
    function mint(uint256 amount, bytes memory userData, bytes memory operatorData)
    public
    override
    onlyMintRole {
        _mint(SOMA.mintTo(), amount, userData, operatorData);
    }

    function _mint(address to, uint256 amount, bytes memory userData, bytes memory operatorData) internal virtual;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC777PermitUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/governance/utils/IVotesUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @notice Abstract ERC777VotesUpgradeable contract. This is based on the OpenZeppelin's ERC777VotesUpgradeable contract.
 */
abstract contract ERC777VotesUpgradeable is Initializable, IVotesUpgradeable, ERC777PermitUpgradeable {

    /**
     * @notice Unchained initializer.
     */
    function __ERC777Votes_init_unchained() internal onlyInitializing {
    }

    /**
     * @notice Checkpoint structure.
     * @param fromBlock The block number of the checkpoint.
     * @param votes The votes balance.
     */
    struct Checkpoint {
        uint32 fromBlock;
        uint224 votes;
    }

    bytes32 private constant _DELEGATION_TYPEHASH =
        keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    mapping(address => address) private _delegates;
    mapping(address => Checkpoint[]) private _checkpoints;
    Checkpoint[] private _totalSupplyCheckpoints;

    /**
     * @notice Returns the `pos`-th checkpoint for `account`.
     * @param account The account to return the checkpoint of.
     * @param pos The position of the checkpoint to return in the array of checkpoints.
     * @return The checkpoint.
     */
    function checkpoints(address account, uint32 pos) public view virtual returns (Checkpoint memory) {
        return _checkpoints[account][pos];
    }

    /**
     * @notice Returns number of checkpoints for `account`.
     * @param account The account to return the number of checkpoints for.
     * @return The number of checkpoints for `account`.
     */
    function numCheckpoints(address account) public view virtual returns (uint32) {
        return SafeCastUpgradeable.toUint32(_checkpoints[account].length);
    }

    /**
     * @notice Returns the address `account` is currently delegating to.
     * @param account The account to return the delegates of.
     * @return The address `account` is delegating to.
     */
    function delegates(address account) public view virtual override returns (address) {
        return _delegates[account];
    }

    /**
     * @notice Returns the current votes balance for `account`
     * @param account The account to return the votes of.
     * @return The votes balance of `account`.
     */
    function getVotes(address account) public view virtual override returns (uint256) {
        uint256 pos = _checkpoints[account].length;
        return pos == 0 ? 0 : _checkpoints[account][pos - 1].votes;
    }

    /**
     * @notice Returns the number of votes for `account` at the end of `blockNumber`.
     * @param account The number of votes for `account` at the end of `blockNumber`.
     * @param blockNumber The block number to count votes until, inclusive.
     * @custom:requirement `blockNumber` must have been already mined.
     * @return The number of votes.
     */
    function getPastVotes(address account, uint256 blockNumber) public view virtual override returns (uint256) {
        require(blockNumber < block.number, "ERC777Votes: block not yet mined");
        return _checkpointsLookup(_checkpoints[account], blockNumber);
    }

    /**
     * @notice Retrieve the `totalSupply` at the end of `blockNumber`. Note, this value is the sum of all balances.
     * It is but NOT the sum of all the delegated votes!
     * @param blockNumber The block number to cumulate total supply until, inclusive.
     * @custom:requirement `blockNumber` must have been already mined.
     */
    function getPastTotalSupply(uint256 blockNumber) public view virtual override returns (uint256) {
        require(blockNumber < block.number, "ERC777Votes: block not yet mined");
        return _checkpointsLookup(_totalSupplyCheckpoints, blockNumber);
    }

    /**
     * @notice Lookup a value in a list of (sorted) checkpoints.
     */
    function _checkpointsLookup(Checkpoint[] storage ckpts, uint256 blockNumber) private view returns (uint256) {
        // We run a binary search to look for the earliest checkpoint taken after `blockNumber`.
        //
        // During the loop, the index of the wanted checkpoint remains in the range [low-1, high).
        // With each iteration, either `low` or `high` is moved towards the middle of the range to maintain the invariant.
        // - If the middle checkpoint is after `blockNumber`, we look in [low, mid)
        // - If the middle checkpoint is before or equal to `blockNumber`, we look in [mid+1, high)
        // Once we reach a single value (when low == high), we've found the right checkpoint at the index high-1, if not
        // out of bounds (in which case we're looking too far in the past and the result is 0).
        // Note that if the latest checkpoint available is exactly for `blockNumber`, we end up with an index that is
        // past the end of the array, so we technically don't find a checkpoint after `blockNumber`, but it works out
        // the same.
        uint256 high = ckpts.length;
        uint256 low = 0;
        while (low < high) {
            uint256 mid = MathUpgradeable.average(low, high);
            if (ckpts[mid].fromBlock > blockNumber) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        return high == 0 ? 0 : ckpts[high - 1].votes;
    }

    /**
     * @notice Delegate votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) public virtual override {
        _delegate(_msgSender(), delegatee);
    }

    /**
     * @notice Delegates votes from signer to `delegatee`
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= expiry, "ERC777Votes: signature expired");
        address signer = ECDSAUpgradeable.recover(
            _hashTypedDataV4(keccak256(abi.encode(_DELEGATION_TYPEHASH, delegatee, nonce, expiry))),
            v,
            r,
            s
        );
        require(nonce == _useNonce(signer), "ERC777Votes: invalid nonce");
        _delegate(signer, delegatee);
    }

    /**
     * @notice Maximum token supply. Defaults to `type(uint224).max` (2^224^ - 1).
     */
    function _maxSupply() internal view virtual returns (uint224) {
        return type(uint224).max;
    }

    /**
     * @notice Snapshots the totalSupply after it has been increased.
     */
    function _mint(
        address account,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData
    ) internal virtual override {
        super._mint(account, amount, userData, operatorData);
        require(totalSupply() <= _maxSupply(), "ERC777Votes: total supply risks overflowing votes");

        _writeCheckpoint(_totalSupplyCheckpoints, _add, amount);
    }

    /**
     * @notice Snapshots the totalSupply after it has been decreased.
     */
    function _burn(
        address account,
        uint256 amount,
        bytes memory userData,
        bytes memory operatorData
    ) internal virtual override {
        super._burn(account, amount, userData, operatorData);

        _writeCheckpoint(_totalSupplyCheckpoints, _subtract, amount);
    }

    /**
     * @notice Move voting power when tokens are transferred.
     *
     * Emits a {DelegateVotesChanged} event.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, amount);

        _moveVotingPower(delegates(from), delegates(to), amount);
    }

    /**
     * @notice Change delegation for `delegator` to `delegatee`.
     *
     * Emits events {DelegateChanged} and {DelegateVotesChanged}.
     */
    function _delegate(address delegator, address delegatee) internal virtual {
        address currentDelegate = delegates(delegator);
        uint256 delegatorBalance = balanceOf(delegator);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveVotingPower(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveVotingPower(
        address src,
        address dst,
        uint256 amount
    ) private {
        if (src != dst && amount > 0) {
            if (src != address(0)) {
                (uint256 oldWeight, uint256 newWeight) = _writeCheckpoint(_checkpoints[src], _subtract, amount);
                emit DelegateVotesChanged(src, oldWeight, newWeight);
            }

            if (dst != address(0)) {
                (uint256 oldWeight, uint256 newWeight) = _writeCheckpoint(_checkpoints[dst], _add, amount);
                emit DelegateVotesChanged(dst, oldWeight, newWeight);
            }
        }
    }

    function _writeCheckpoint(
        Checkpoint[] storage ckpts,
        function(uint256, uint256) view returns (uint256) op,
        uint256 delta
    ) private returns (uint256 oldWeight, uint256 newWeight) {
        uint256 pos = ckpts.length;
        oldWeight = pos == 0 ? 0 : ckpts[pos - 1].votes;
        newWeight = op(oldWeight, delta);

        if (pos > 0 && ckpts[pos - 1].fromBlock == block.number) {
            ckpts[pos - 1].votes = SafeCastUpgradeable.toUint224(newWeight);
        } else {
            ckpts.push(Checkpoint({fromBlock: SafeCastUpgradeable.toUint32(block.number), votes: SafeCastUpgradeable.toUint224(newWeight)}));
        }
    }

    function _add(uint256 a, uint256 b) private pure returns (uint256) {
        return a + b;
    }

    function _subtract(uint256 a, uint256 b) private pure returns (uint256) {
        return a - b;
    }
    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC777/ERC777Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @notice ERC777 token with pausable token transfers, minting and burning.
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 * This is based on the OpenZeppelin's ERC777PausableUpgradeable contract.
 */
abstract contract ERC777PausableUpgradeable is Initializable, ERC777Upgradeable, PausableUpgradeable {

    /**
     * @notice Initializer for extended contracts.
     */
    function __ERC777Pausable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Pausable_init_unchained();
        __ERC777Pausable_init_unchained();
    }

    /**
     * @notice Unchained initializer.
     */
    function __ERC777Pausable_init_unchained() internal onlyInitializing {
    }

    /**
     * @notice Receive hook called before any token transfer.
     * @dev See {ERC777-_beforeTokenTransfer}.
     * @custom:requirement The contract must not be paused.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, amount);

        require(!paused(), "ERC777Pausable: token transfer while paused");
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC777/IERC777.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC777Token standard as defined in the EIP.
 *
 * This contract uses the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 registry standard] to let
 * token holders and recipients react to token movements by using setting implementers
 * for the associated interfaces in said registry. See {IERC1820Registry} and
 * {ERC1820Implementer}.
 */
interface IERC777Upgradeable {
    /**
     * @dev Emitted when `amount` tokens are created by `operator` and assigned to `to`.
     *
     * Note that some additional user `data` and `operatorData` can be logged in the event.
     */
    event Minted(address indexed operator, address indexed to, uint256 amount, bytes data, bytes operatorData);

    /**
     * @dev Emitted when `operator` destroys `amount` tokens from `account`.
     *
     * Note that some additional user `data` and `operatorData` can be logged in the event.
     */
    event Burned(address indexed operator, address indexed from, uint256 amount, bytes data, bytes operatorData);

    /**
     * @dev Emitted when `operator` is made operator for `tokenHolder`
     */
    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);

    /**
     * @dev Emitted when `operator` is revoked its operator status for `tokenHolder`
     */
    event RevokedOperator(address indexed operator, address indexed tokenHolder);

    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the smallest part of the token that is not divisible. This
     * means all token operations (creation, movement and destruction) must have
     * amounts that are a multiple of this number.
     *
     * For most token contracts, this value will equal 1.
     */
    function granularity() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by an account (`owner`).
     */
    function balanceOf(address owner) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * If send or receive hooks are registered for the caller and `recipient`,
     * the corresponding functions will be called with `data` and empty
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function send(
        address recipient,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev Destroys `amount` tokens from the caller's account, reducing the
     * total supply.
     *
     * If a send hook is registered for the caller, the corresponding function
     * will be called with `data` and empty `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - the caller must have at least `amount` tokens.
     */
    function burn(uint256 amount, bytes calldata data) external;

    /**
     * @dev Returns true if an account is an operator of `tokenHolder`.
     * Operators can send and burn tokens on behalf of their owners. All
     * accounts are their own operator.
     *
     * See {operatorSend} and {operatorBurn}.
     */
    function isOperatorFor(address operator, address tokenHolder) external view returns (bool);

    /**
     * @dev Make an account an operator of the caller.
     *
     * See {isOperatorFor}.
     *
     * Emits an {AuthorizedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function authorizeOperator(address operator) external;

    /**
     * @dev Revoke an account's operator status for the caller.
     *
     * See {isOperatorFor} and {defaultOperators}.
     *
     * Emits a {RevokedOperator} event.
     *
     * Requirements
     *
     * - `operator` cannot be calling address.
     */
    function revokeOperator(address operator) external;

    /**
     * @dev Returns the list of default operators. These accounts are operators
     * for all token holders, even if {authorizeOperator} was never called on
     * them.
     *
     * This list is immutable, but individual holders may revoke these via
     * {revokeOperator}, in which case {isOperatorFor} will return false.
     */
    function defaultOperators() external view returns (address[] memory);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient`. The caller must
     * be an operator of `sender`.
     *
     * If send or receive hooks are registered for `sender` and `recipient`,
     * the corresponding functions will be called with `data` and
     * `operatorData`. See {IERC777Sender} and {IERC777Recipient}.
     *
     * Emits a {Sent} event.
     *
     * Requirements
     *
     * - `sender` cannot be the zero address.
     * - `sender` must have at least `amount` tokens.
     * - the caller must be an operator for `sender`.
     * - `recipient` cannot be the zero address.
     * - if `recipient` is a contract, it must implement the {IERC777Recipient}
     * interface.
     */
    function operatorSend(
        address sender,
        address recipient,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the total supply.
     * The caller must be an operator of `account`.
     *
     * If a send hook is registered for `account`, the corresponding function
     * will be called with `data` and `operatorData`. See {IERC777Sender}.
     *
     * Emits a {Burned} event.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     * - the caller must be an operator for `account`.
     */
    function operatorBurn(
        address account,
        uint256 amount,
        bytes calldata data,
        bytes calldata operatorData
    ) external;

    event Sent(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes data,
        bytes operatorData
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC777/IERC777Recipient.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC777TokensRecipient standard as defined in the EIP.
 *
 * Accounts can be notified of {IERC777} tokens being sent to them by having a
 * contract implement this interface (contract holders can be their own
 * implementer) and registering it on the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 global registry].
 *
 * See {IERC1820Registry} and {ERC1820Implementer}.
 */
interface IERC777RecipientUpgradeable {
    /**
     * @dev Called by an {IERC777} token contract whenever tokens are being
     * moved or created into a registered account (`to`). The type of operation
     * is conveyed by `from` being the zero address or not.
     *
     * This call occurs _after_ the token contract's state is updated, so
     * {IERC777-balanceOf}, etc., can be used to query the post-operation state.
     *
     * This function may revert to prevent the operation from being executed.
     */
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC777/IERC777Sender.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC777TokensSender standard as defined in the EIP.
 *
 * {IERC777} Token holders can be notified of operations performed on their
 * tokens by having a contract implement this interface (contract holders can be
 * their own implementer) and registering it on the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 global registry].
 *
 * See {IERC1820Registry} and {ERC1820Implementer}.
 */
interface IERC777SenderUpgradeable {
    /**
     * @dev Called by an {IERC777} token contract whenever a registered holder's
     * (`from`) tokens are about to be moved or destroyed. The type of operation
     * is conveyed by `to` being the zero address or not.
     *
     * This call occurs _before_ the token contract's state is updated, so
     * {IERC777-balanceOf}, etc., can be used to query the pre-operation state.
     *
     * This function may revert to prevent the operation from being executed.
     */
    function tokensToSend(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/introspection/IERC1820Registry.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the global ERC1820 Registry, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1820[EIP]. Accounts may register
 * implementers for interfaces in this registry, as well as query support.
 *
 * Implementers may be shared by multiple accounts, and can also implement more
 * than a single interface for each account. Contracts can implement interfaces
 * for themselves, but externally-owned accounts (EOA) must delegate this to a
 * contract.
 *
 * {IERC165} interfaces can also be queried via the registry.
 *
 * For an in-depth explanation and source code analysis, see the EIP text.
 */
interface IERC1820RegistryUpgradeable {
    event InterfaceImplementerSet(address indexed account, bytes32 indexed interfaceHash, address indexed implementer);

    event ManagerChanged(address indexed account, address indexed newManager);

    /**
     * @dev Sets `newManager` as the manager for `account`. A manager of an
     * account is able to set interface implementers for it.
     *
     * By default, each account is its own manager. Passing a value of `0x0` in
     * `newManager` will reset the manager to this initial state.
     *
     * Emits a {ManagerChanged} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     */
    function setManager(address account, address newManager) external;

    /**
     * @dev Returns the manager for `account`.
     *
     * See {setManager}.
     */
    function getManager(address account) external view returns (address);

    /**
     * @dev Sets the `implementer` contract as ``account``'s implementer for
     * `interfaceHash`.
     *
     * `account` being the zero address is an alias for the caller's address.
     * The zero address can also be used in `implementer` to remove an old one.
     *
     * See {interfaceHash} to learn how these are created.
     *
     * Emits an {InterfaceImplementerSet} event.
     *
     * Requirements:
     *
     * - the caller must be the current manager for `account`.
     * - `interfaceHash` must not be an {IERC165} interface id (i.e. it must not
     * end in 28 zeroes).
     * - `implementer` must implement {IERC1820Implementer} and return true when
     * queried for support, unless `implementer` is the caller. See
     * {IERC1820Implementer-canImplementInterfaceForAddress}.
     */
    function setInterfaceImplementer(
        address account,
        bytes32 _interfaceHash,
        address implementer
    ) external;

    /**
     * @dev Returns the implementer of `interfaceHash` for `account`. If no such
     * implementer is registered, returns the zero address.
     *
     * If `interfaceHash` is an {IERC165} interface id (i.e. it ends with 28
     * zeroes), `account` will be queried for support of it.
     *
     * `account` being the zero address is an alias for the caller's address.
     */
    function getInterfaceImplementer(address account, bytes32 _interfaceHash) external view returns (address);

    /**
     * @dev Returns the interface hash for an `interfaceName`, as defined in the
     * corresponding
     * https://eips.ethereum.org/EIPS/eip-1820#interface-name[section of the EIP].
     */
    function interfaceHash(string calldata interfaceName) external pure returns (bytes32);

    /**
     * @notice Updates the cache with whether the contract implements an ERC165 interface or not.
     * @param account Address of the contract for which to update the cache.
     * @param interfaceId ERC165 interface for which to update the cache.
     */
    function updateERC165Cache(address account, bytes4 interfaceId) external;

    /**
     * @notice Checks whether a contract implements an ERC165 interface or not.
     * If the result is not cached a direct lookup on the contract address is performed.
     * If the result is not cached or the cached value is out-of-date, the cache MUST be updated manually by calling
     * {updateERC165Cache} with the contract address.
     * @param account Address of the contract to check.
     * @param interfaceId ERC165 interface to check.
     * @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165Interface(address account, bytes4 interfaceId) external view returns (bool);

    /**
     * @notice Checks whether a contract implements an ERC165 interface or not without using nor updating the cache.
     * @param account Address of the contract to check.
     * @param interfaceId ERC165 interface to check.
     * @return True if `account` implements `interfaceId`, false otherwise.
     */
    function implementsERC165InterfaceNoCache(address account, bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../../SomaAccessControl/utils/AccessibleUpgradeable.sol";

import "../ISomaGuard.sol";

import "./GuardHelper.sol";
import "./IGuardable.sol";

abstract contract GuardableUpgradeable is IGuardable, AccessibleUpgradeable {

    function __Guardable__init() internal {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __Guardable__init_unchained();
        __SomaContract_init_unchained();
        __Accessible_init_unchained();
    }

    function __Guardable__init_unchained() internal onlyInitializing {
        LOCAL_UPDATE_PRIVILEGES_ROLE = keccak256(abi.encodePacked(address(this), GLOBAL_UPDATE_PRIVILEGES_ROLE));
        _updateRequiredPrivileges(bytes32(type(uint256).max));
    }

    bytes32 public immutable DEFAULT_PRIVILEGES = GuardHelper.DEFAULT_PRIVILEGES;
    bytes32 public constant GLOBAL_UPDATE_PRIVILEGES_ROLE = keccak256('Guardable.GLOBAL_UPDATE_PRIVILEGES_ROLE');

    bytes32 public LOCAL_UPDATE_PRIVILEGES_ROLE;
    bytes32 private _requiredPrivileges;

    modifier onlyApprovedPrivileges(address sender) {
        require(hasPrivileges(sender), 'required privileges not met');
        _;
    }

    function hasPrivileges(address account) public view virtual override returns (bool) {
        return ISomaGuard(SOMA.guard()).check(account, requiredPrivileges());
    }

    function requiredPrivileges() public view virtual override returns (bytes32) {
        return _requiredPrivileges;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IGuardable).interfaceId || super.supportsInterface(interfaceId);
    }

    function updateRequiredPrivileges(bytes32 newRequiredPrivileges) external virtual override returns (bool) {
        require(
            hasRole(LOCAL_UPDATE_PRIVILEGES_ROLE, _msgSender()) || hasRole(GLOBAL_UPDATE_PRIVILEGES_ROLE, _msgSender()),
            'Guardable: you do not have the required roles to do this'
        );
        _updateRequiredPrivileges(newRequiredPrivileges);
        return true;
    }

    function _updateRequiredPrivileges(bytes32 newRequiredPrivileges) internal {
        emit RequiredPrivilegesUpdated(_requiredPrivileges, newRequiredPrivileges, _msgSender());
        _requiredPrivileges = newRequiredPrivileges;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/**
 * @title SOMA ERC777 Guard Contract.
 * @author SOMA.finance.
 * @notice Interface of the {ERC777Guard} contract.
 */
interface IERC777Guard {

    /**
     * @notice Checks that both `from` and `to` have the required privileges. Ignores address zero.
     * @param from The address sending the tokens.
     * @param to The address receiving the tokens.
     * @param amount The amount of tokens to transfer.
     * @return True if the transfer is valid.
     */
    function canTransferFrom(address from, address to, uint256 amount) external view returns (bool);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/IAccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";

import "../../utils/security/IPausable.sol";
import "../../utils/SomaContractUpgradeable.sol";

import "../ISomaAccessControl.sol";
import "./IAccessible.sol";

abstract contract AccessibleUpgradeable is IAccessible, SomaContractUpgradeable {

    function __Accessible_init() internal onlyInitializing {
        __SomaContract_init_unchained();
    }

    function __Accessible_init_unchained() internal onlyInitializing {
    }

    modifier onlyRole(bytes32 role) {
        require(hasRole(role, _msgSender()), "SomaAccessControl: caller does not have the appropriate authority");
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessible).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    // slither-disable-next-line external-function
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return IAccessControlUpgradeable(SOMA.access()).getRoleAdmin(role);
    }

    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return IAccessControlUpgradeable(SOMA.access()).hasRole(role, account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title SOMA Guard Contract.
 * @author SOMA.finance
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 * @notice A contract to batch update account privileges.
 */
interface ISomaGuard {

    /**
     * @notice Emitted when privileges for a 2D array of accounts are updated.
     * @param accounts The 2D array of addresses.
     * @param privileges The array of privileges.
     * @param sender The address of the message sender.
     */
    event BatchUpdate(
        address[][] accounts,
        bytes32[] privileges,
        address indexed sender
    );

    /**
     * @notice Emitted when privileges for an array of accounts are updated.
     * @param accounts The array of addresses.
     * @param access The array of privileges.
     * @param sender The address of the message sender.
     */
    event BatchUpdateSingle(
        address[] accounts,
        bytes32[] access,
        address indexed sender
    );

    /**
     * @notice Returns the default privileges of the SomaGuard contract.
     * @dev Returns bytes32(uint256(2 ** 64 - 1)).
     */
    function DEFAULT_PRIVILEGES() external view returns (bytes32);

    /**
     * @notice Returns the operator role of the SomaGuard contract.
     * @dev Returns bytes32(uint256(3)).
     */
    function OPERATOR_ROLE() external view returns (bytes32);

    /**
     * @notice Returns the privilege of an account.
     * @param account The account to return the privilege of.
     */
    function privileges(address account) external view returns (bytes32);

    /**
     * @notice Returns True if an account passes a query, where query is the desired privileges.
     * @param account The account to check the privileges of.
     * @param query The desired privileges to check for.
     */
    function check(address account, bytes32 query) external view returns (bool);

    /**
     * @notice Returns the privileges for each account.
     * @param accounts The array of accounts return the privileges of.
     * @return access_ The array of privileges.
     */
    function batchFetch(address[] calldata accounts) external view returns (bytes32[] memory access_);

    /**
     * @notice Updates the privileges of an array of accounts.
     * @param accounts_ The array of addresses to accumulate privileges of.
     * @param access_ The array of privileges to update the array of accounts with.
     * @return True if the batch update was successful.
     */
    function batchUpdate(address[] calldata accounts_, bytes32[] calldata access_) external returns (bool);

    /**
     * @notice Updates the privileges of a 2D array of accounts, where the child array of accounts are all assigned to the
     * same privileges.
     * @param accounts_ The array of addresses to accumulate privileges of.
     * @param access_ The array of privileges to update the 2D array of accounts with.
     * @return True if the batch update was successful.
     */
    function batchUpdate(address[][] calldata accounts_, bytes32[] calldata access_) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./IGuardable.sol";

library GuardHelper {

    // 00000000(192 0's repeated)111(64times)
    // (64 default on, 192 default off)
    bytes32 internal constant DEFAULT_PRIVILEGES = bytes32(uint256(2 ** 64 - 1));

    function requiredPrivileges(address account) internal view returns (bytes32 privileges) {
        try IGuardable(account).requiredPrivileges() returns (bytes32 requiredPrivileges_) {
            privileges = requiredPrivileges_;
        } catch(bytes memory) {
            privileges = DEFAULT_PRIVILEGES;
        }
    }

    function check(bytes32 privileges, bytes32 query) internal pure returns (bool) {
        return privileges & query == query;
    }

    function mergePrivileges(bytes32 privileges1, bytes32 privileges2) internal pure returns (bytes32) {
        return privileges1 | privileges2;
    }

    function mergePrivileges(bytes32 privileges1, bytes32 privileges2, bytes32 privileges3) internal pure returns (bytes32) {
        return privileges1 | privileges2 | privileges3;
    }

    function switchOn(uint256[] memory ids, bytes32 base) internal pure returns (bytes32 result) {
        result = base;
        for (uint i; i < ids.length; ++i) {
            result = result | bytes32(2**ids[i]);
        }
    }

    function switchOff(uint256[] memory ids, bytes32 base) internal pure returns (bytes32 result) {
        result = base;
        for (uint i; i < ids.length; ++i) {
            result = result & bytes32(type(uint256).max - 2**ids[i]);
        }
        result = result | DEFAULT_PRIVILEGES;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IGuardable {
    event RequiredPrivilegesUpdated(bytes32 prevPrivileges, bytes32 newPrivileges, address indexed sender);

    // Privileges Control
    function hasPrivileges(address account) external view returns (bool);
    function requiredPrivileges() external view returns (bytes32);
    function updateRequiredPrivileges(bytes32) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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

pragma solidity ^0.8.9;

interface IPausable {

    function paused() external view returns (bool);

    function pause() external;

    function unpause() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/MulticallUpgradeable.sol";

import "../ISOMA.sol";
import "../SOMAlib.sol";

import "./ISomaContract.sol";

contract SomaContractUpgradeable is ISomaContract, PausableUpgradeable, ERC165Upgradeable, MulticallUpgradeable {
    function __SomaContract_init() internal onlyInitializing {
        __ERC165_init_unchained();
        __Context_init_unchained();
        __SomaContract_init_unchained();
    }

    function __SomaContract_init_unchained() internal onlyInitializing {}

    ISOMA public immutable override SOMA = SOMAlib.SOMA;

    modifier onlyMasterOrSubMaster {
        address sender = _msgSender();
        require(SOMA.master() == sender || SOMA.subMaster() == sender, 'SOMA: MASTER or SUB MASTER only');
        _;
    }

    function pause() external virtual override onlyMasterOrSubMaster {
        _pause();
    }

    function unpause() external virtual override onlyMasterOrSubMaster {
        _unpause();
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(ISomaContract).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function paused() public view virtual override returns (bool) {
        return PausableUpgradeable(address(SOMA)).paused() || super.paused();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/**
 * @title SOMA Access Control Contract.
 * @author SOMA.finance.
 * @notice An access control contract that establishes a hierarchy of accounts and controls
 * function call permissions.
 */
interface ISomaAccessControl {

    /**
     * @notice Sets the admin of a role.
     * @dev Sets the admin for the `role` role.
     * @param role The role to set the admin role of.
     * @param adminRole The admin of `role`.
     */
    function setRoleAdmin(bytes32 role, bytes32 adminRole) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IAccessible {

    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function hasRole(bytes32 role, address account) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Multicall.sol)

pragma solidity ^0.8.0;

import "./AddressUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides a function to batch together multiple calls in a single external call.
 *
 * _Available since v4.1._
 */
abstract contract MulticallUpgradeable is Initializable {
    function __Multicall_init() internal onlyInitializing {
    }

    function __Multicall_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev Receives and executes a batch of function calls on this contract.
     */
    function multicall(bytes[] calldata data) external virtual returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            results[i] = _functionDelegateCall(address(this), data[i]);
        }
        return results;
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./SomaAccessControl/ISomaAccessControl.sol";
import "./SomaSwap/periphery/ISomaSwapRouter.sol";
import "./SomaSwap/core/interfaces/ISomaSwapFactory.sol";
import "./SomaGuard/ISomaGuard.sol";
import "./TemplateFactory/ITemplateFactory.sol";
import "./Lockdrop/ILockdropFactory.sol";

/**
 * @title SOMA Contract.
 * @author SOMA.finance
 * @notice Interface of the SOMA contract.
 */
interface ISOMA {

    /**
     * @notice Emitted when the SOMA snapshot is updated.
     * @param version The version of the new snapshot.
     * @param hash The hash of the new snapshot.
     * @param snapshot The new snapshot.
     */
    event SOMAUpgraded(bytes32 indexed version, bytes32 indexed hash, bytes snapshot);

    /**
     * @notice Emitted when the `seizeTo` address is updated.
     * @param prevSeizeTo The address of the previous `seizeTo`.
     * @param newSeizeTo The address of the new `seizeTo`.
     * @param sender The address of the message sender.
     */
    event SeizeToUpdated(
        address indexed prevSeizeTo,
        address indexed newSeizeTo,
        address indexed sender
    );

    /**
     * @notice Emitted when the `mintTo` address is updated.
     * @param prevMintTo The address of the previous `mintTo`.
     * @param newMintTo The address of the new `mintTo`.
     * @param sender The address of the message sender.
     */
    event MintToUpdated(
        address indexed prevMintTo,
        address indexed newMintTo,
        address indexed sender
    );

    /**
     * @notice Snapshot of the SOMA contracts.
     * @param master The master address.
     * @param subMaster The subMaster address.
     * @param access The ISomaAccessControl contract.
     * @param guard The ISomaGuard contract.
     * @param factory The ITemplateFactory contract.
     * @param token The IERC20 contract.
     */
    struct Snapshot {
        address master;
        address subMaster;
        address access;
        address guard;
        address factory;
        address token;
    }

    /**
     * @notice Returns the address that has been assigned the master role.
     */
    function master() external view returns (address);

    /**
     * @notice Returns the address that has been assigned the subMaster role.
     */
    function subMaster() external view returns (address);

    /**
     * @notice Returns the address of the {ISomaAccessControl} contract.
     */
    function access() external view returns (address);

    /**
     * @notice Returns the address of the {ISomaGuard} contract.
     */
    function guard() external view returns (address);

    /**
     * @notice Returns the address of the {ITemplateFactory} contract.
     */
    function factory() external view returns (address);

    /**
     * @notice Returns the address of the {IERC20} contract.
     */
    function token() external view returns (address);

    /**
     * @notice Returns the hash of the latest snapshot.
     */
    function snapshotHash() external view returns (bytes32);

    /**
     * @notice Returns the latest snapshot version.
     */
    function snapshotVersion() external view returns (bytes32);

    /**
     * @notice Returns the snapshot, given a snapshot hash.
     * @param hash The snapshot hash.
     * @return _snapshot The snapshot matching the `hash`.
     */
    function snapshots(bytes32 hash) external view returns (bytes memory _snapshot);

    /**
     * @notice Returns the hash when given a version, returns a version when given a hash.
     * @param versionOrHash The version or hash.
     * @return hashOrVersion The hash or version based on the input.
     */
    function versions(bytes32 versionOrHash) external view returns (bytes32 hashOrVersion);

    /**
     * @notice Returns the address that receives all minted tokens.
     */
    function mintTo() external view returns (address);

    /**
     * @notice Returns the address that receives all seized tokens.
     */
    function seizeTo() external view returns (address);

    /**
     * @notice Updates the current SOMA snapshot and is called after the proxy has been upgraded.
     * @param version The version to upgrade to.
     * @custom:emits SOMAUpgraded
     * @custom:requirement The incoming snapshot hash cannot be equal to the contract's existing snapshot hash.
     */
    function __upgrade(bytes32 version) external;

    /**
     * @notice Triggers the SOMA paused state. Pauses all the SOMA contracts.
     * @custom:emits Paused
     * @custom:requirement SOMA must be already unpaused.
     * @custom:requirement The caller must be the master or subMaster.
     */
    function pause() external;

    /**
     * @notice Triggers the SOMA unpaused state. Unpauses all the SOMA contracts.
     * @custom:emits Unpaused
     * @custom:requirement SOMA must be already paused.
     * @custom:requirement The caller must be the master or subMaster.
     */
    function unpause() external;

    /**
     * @notice Sets the `mintTo` address to `_mintTo`.
     * @param _mintTo The address to be set as the `mintTo` address.
     * @custom:emits MintToUpdated
     * @custom:requirement The caller must be the master.
     */
    function setMintTo(address _mintTo) external;

    /**
     * @notice Sets the `seizeTo` address to `_seizeTo`.
     * @param _seizeTo The address to be set as the `seizeTo` address.
     * @custom:emits SeizeToUpdated
     * @custom:requirement The caller must be the master.
     */
    function setSeizeTo(address _seizeTo) external;

    /**
     * @notice Returns the current snapshot of the SOMA contracts.
     */
    function snapshot() external view returns (Snapshot memory _snapshot);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ISOMA.sol";

library SOMAlib {

    /**
     * @notice The fixed address where the SOMA contract will be located (this is a proxy).
     */
    ISOMA public constant SOMA = ISOMA(0x9b5d99a5ae8Ab7240fd9c33b173e4A68f73ae9B8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "../ISOMA.sol";

interface ISomaContract {

    function pause() external;
    function unpause() external;

    function SOMA() external view returns (ISOMA);
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

pragma solidity >=0.6.2;

/**
 * @title SOMA Swap Router Contract.
 * @author SOMA.finance
 * @notice Interface for the {SomaSwapRouter} contract.
 */
interface ISomaSwapRouter {

    /**
     * @notice Returns the address of the factory contract.
     */
    function factory() external view returns (address);

    /**
     * @notice Returns the address of the WETH token.
     */
    function WETH() external view returns (address);

    /**
     * @notice Adds liquidity to the pool.
     * @param tokenA The token0 of the pair to add liquidity to.
     * @param tokenB The token1 of the pair to add liquidity to.
     * @param amountADesired The amount of token0 to add as liquidity.
     * @param amountBDesired The amount of token1 to add as liquidity.
     * @param amountAMin The bound of the tokenB / tokenA price can go up
     * before transaction reverts.
     * @param amountBMin The bound of the tokenA / tokenB price can go up
     * before transaction reverts.
     * @custom:requirement `tokenA` and `tokenB` pair must already exist.
     * @custom:requirement the router's expiration deadline must be greater than the timestamp of the
     * function call
     * @return amountA The amount of tokenA added as liquidity.
     * @return amountB The amount of tokenB added as liquidity.
     * @return liquidity The amount of liquidity tokens minted.
     */
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    /**
     * @notice Adds liquidity to the pool with ETH.
     * @param token The pool token.
     * @param amountTokenDesired The amount of token to add as liquidity if WETH/token price
     * is less or equal to the value of msg.value/amountTokenDesired (token depreciates).
     * @param amountTokenMin The bound that WETH/token price can go up before the transactions
     * reverts.
     * @param amountETHMin The bound that token/WETH price can go up before the transaction reverts.
     * @param to The recipient of the liquidity tokens.
     * @param deadline The unix timestamp after which the transaction will revert.
     * @custom:requirement `tokenA` and `tokenB` pair must already exist.
     * @custom:requirement the router's expiration deadline must be greater than the timestamp of the
     * function call
     * @return amountToken The amount of token sent to the pool.
     * @return amountETH The amount of ETH converted to WETH and sent to the pool.
     * @return liquidity The amount of liquidity tokens minted.
     */
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    /**
     * @notice Removes liquidity from the pool.
     * @param tokenA The pool token.
     * @param tokenB The pool token.
     * @param liquidity The amount of liquidity tokens to remove.
     * @param amountAMin The minimum amount of tokenA that must be received
     * for the transaction not to revert.
     * @param amountBMin The minimum amount of tokenB that must be received
     * for the transaction not to revert.
     * @param to The recipient of the underlying asset.
     * @param deadline The unix timestamp after which the transaction will revert.
     * @custom:requirement `amountA` must be greater than or equal to `amountAMin`.
     * @custom:requirement `amountB` must be greater than or equal to `amountBMin`.
     * @return amountA The amount of tokenA received.
     * @return amountB The amount of tokenB received.
     */
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    /**
     * @notice Removes liquidity from the pool and the caller receives ETH.
     * @param token The pool token.
     * @param liquidity The amount of liquidity tokens to remove.
     * @param amountTokenMin The minimum amount of tokens that must be received
     * for the transaction not to revert.
     * @param amountETHMin The minimum amount of ETH that must be received for the
     * transaction not to revert.
     * @param to The recipient of the underlying assets.
     * @param deadline The unix timestamp after which the transaction will revert.
     * @custom:requirement `amountA` must be greater than or equal to `amountAMin`.
     * @custom:requirement `amountB` must be greater than or equal to `amountBMin`.
     * @return amountToken The amount of token received.
     * @return amountETH The amount of ETH received.
     */
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    /**
     * @notice Removes liquidity from the pool without pre-approval.
     * @param tokenA The pool token0.
     * @param tokenB The pool token1.
     * @param liquidity The amount of liquidity to remove.
     * @param amountAMin The minimum amount of tokenA that must be received for the
     * transaction not to revert.
     * @param amountBMin The minimum amount of tokenB that must be received for the
     * transaction not to revert.
     * @param to The recipient of the underlying asset.
     * @param deadline The unix timestamp after which the transaction will revert.
     * @param approveMax Boolean value indicating if the approval amount in the signature
     * is for liquidity or uint(-1).
     * @param v The v component of the permit signature.
     * @param r The r component of the permit signature.
     * @param s The s component of the permit signature.
     * @custom:requirement `amountA` must be greater than or equal to `amountAMin`.
     * @custom:requirement `amountB` must be greater than or equal to `amountBMin`.
     * @return amountA The amount of tokenA received.
     * @return amountB The amount of tokenB received.
     */
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);

    /**
     * @notice Removes liquidity from the pool and the caller receives ETH without pre-approval.
     * @param token The pool token.
     * @param liquidity The amount of liquidity to remove.
     * @param amountTokenMin The minimum amount of token that must be received for the transaction
     * not to revert.
     * @param amountETHMin The minimum amount of ETH that must be received for the transaction not
     * to revert.
     * @param to The recipient of the underlying asset.
     * @param deadline The unix timestamp after which the transaction will revert.
     * @param approveMax Boolean value indicating if the approval amount in the signature
     * is for liquidity or uint(-1).
     * @param v The v component of the permit signature.
     * @param r The r component of the permit signature.
     * @param s The s component of the permit signature.
     * @return amountToken The amount fo token received.
     * @return amountETH The amount of ETH received.
     */
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);

    /**
     * @notice Swaps an exact amount of input tokens for as many output tokens as possible, along
     * with the route determined by the path.
     * @param amountIn The amount of input tokens to send.
     * @param amountOutMin The minimum amount of output tokens that must be received for the transaction
     * not to revert.
     * @param path The array of token addresses, where pools for each pair of addresses must exist and
     * have liquidity.
     * @param to The recipient of the output tokens.
     * @param deadline The unix timestamp after which the transaction will revert.
     * @custom:requirement The value at the last index of `amounts` (from `SomaSwapLibrary.getAmountsOut()`) must be greater than or equal to `amountOutMin`.
     * @return amounts The input token amount and all subsequent output token amounts.
     */
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    /**
     * @notice Caller receives an exact amount of output tokens for as few input input tokens as possible, along
     * with the route determined by the path.
     * @param amountOut The amount of output tokens to receive.
     * @param amountInMax The maximum amount of input tokens that can be required before the transaction reverts.
     * @param path The array of token addresses, where pools for each pair of addresses must exist and
     * have liquidity.
     * @param to The recipient of the output tokens.
     * @param deadline The unix timestamp after which the transaction will revert.
     * @custom:requirement The value of the first index of `amounts` (from `SomaSwapLibrary.getAmountsIn()`) must be less than or equal to `amountInMax`.
     * @return amounts The input token amount and all subsequent output token amounts.
     */
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    /**
     * @notice Swaps an exact amount of ETH for as many output tokens as possible, along with the route
     * determined by the path.
     * @param amountOutMin The minimum amount of output tokens that must be received for the transaction not to revert.
     * @param path The array of token addresses, where pools for each pair of addresses must exist and
     * have liquidity.
     * @param to The recipient of the output tokens.
     * @param deadline The unix timestamp after which the transaction will revert.
     * @custom:requirement The first element of `path` must be equal to the WETH address.
     * @custom:requirement The last element of `amounts` (from `SomaSwapLibrary.getAmountsOut()`) must be greater than or equal to `amount0Min`.
     * @return amounts The input token amount and all subsequent output token amounts.
     */
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    /**
     * @notice Caller receives an exact amount of ETH for as few input tokens as possible, along with the route
     * determined by the path.
     * @param amountOut The amount of ETH to receive.
     * @param amountInMax The maximum amount of input tokens that can be required before the transaction reverts.
     * @param path The array of token addresses, where pools for each pair of addresses must exist and
     * have liquidity.
     * @param to The recipient of the output tokens.
     * @param deadline The unix timestamp after which the transaction will revert.
     * @custom:requirement The last element of `path` must be equal to the WETH address.
     * @custom:requirement The first element of `amounts` (from `SomaSwapLibrary.getAmountsIn()`) must be less than or equal to `amountInMax`.
     * @return amounts The input token amount and all subsequent output token amounts.
     */
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);

    /**
     * @notice Swaps an exact amount of tokens for as much ETH as possible, along with the route determined
     * by the path.
     * @param amountIn The amount of input tokens to send.
     * @param amountOutMin The minimum amount of output tokens that must be received for the transaction not to revert.
     * @param path The array of token addresses, where pools for each pair of addresses must exist and
     * have liquidity.
     * @param to The recipient of the output tokens.
     * @param deadline The unix timestamp after which the transaction will revert.
     * @custom:requirement The last element of `path` must be equal to the WETH address.
     * @custom:requirement The last element of `amounts` (from `SomaSwapLibrary.getAmountsOut()`) must be greater than or
     * equal to `amountOutMin`.
     * @return amounts The input token amount and all subsequent output token amounts.
     */
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);

    /**
     * @notice Caller receives an exact amount of tokens for as little ETH as possible, along with the route determined
     * by the path.
     * @param amountOut The amount of tokens to receive.
     * @param path The array of token addresses, where pools for each pair of addresses must exist and
     * have liquidity.
     * @param to The recipient of the output tokens.
     * @param deadline The unix timestamp after which the transaction will revert.
     * @custom:requirement The first element of `path` must be equal to the WETH address.
     * @custom:requirement The first element of `amounts` (from `SomaSwapLibrary.getAmountIn()`) must be less than or equal
     * to the `msg.value`.
     * @return amounts The input token amount and all subsequent output token amounts.
     */
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    /**
     * @notice Given some asset amount and reserves, returns the amount of the other asset representing equivalent value.
     * @param amountA The amount of token0.
     * @param reserveA The reserves of token0.
     * @param reserveB The reserves of token1.
     * @custom:requirement `amountA` must be greater than zero.
     * @custom:requirement `reserveA` must be greater than zero.
     * @custom:requirement `reserveB` must be greater than zero.
     * @return amountB The amount of token1.
     */
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);

    /**
     * @notice Given some asset amount and reserves, returns the maximum output amount of the other asset (accounting for fees).
     * @param amountIn The amount of the input token.
     * @param reserveIn The reserves of the input token.
     * @param reserveOut The reserves of the output token.
     * @custom:requirement `amountIn` must be greater than zero.
     * @custom:requirement `reserveIn` must be greater than zero.
     * @custom:requirement `reserveOut` must be greater than zero.
     * @return amountOut The amount of the output token.
     */
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);

    /**
     * @notice Returns the minimum input asset amount required to buy the given output asset amount (accounting for fees).
     * @param amountOut The amount of the output token.
     * @param reserveIn The reserves of the input token.
     * @param reserveOut The reserves of the output token.
     * @custom:requirement `amountOut` must be greater than zero.
     * @custom:requirement `reserveIn` must be greater than zero.
     * @custom:requirement `reserveOut` must be greater than zero.
     * @return amountIn The required input amount of the input asset.
     */
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);

    /**
     * @notice Given an input asset amount and an array of token addresses, calculates all subsequent maximum output token amounts
     * calling `getReserves()` for each pair of token addresses in the path in turn, and using these to call `getAmountOut()`.
     * @param amountIn The amount of the input token.
     * @param path The array of token addresses, where pools for each pair of addresses must exist and
     * have liquidity.
     * @custom:requirement `path` length must be greater than or equal to 2.
     * @return amounts The maximum output amounts.
     */
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

    /**
     * @notice Given an output asset amount and an array of token addresses, calculates all preceding minimum input token amounts
     * by calling `getReserves()` for each pair of token addresses in the path in turn, and using these to call `getAmountIn()`.
     * @param amountOut The amount of the output token.
     * @param path The array of token addresses, where pools for each pair of addresses must exist and
     * have liquidity.
     * @custom:requirement `path` length must be greater than or equal to 2.
     * @return amounts The required input amounts.
     */
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

    /**
     * @notice See {ISomaSwapRouter-removeLiquidityETH} - Identical but succeeds for tokens that take a fee on transfer.
     * @param token The pool token.
     * @param liquidity The amount of liquidity tokens to remove.
     * @param amountTokenMin The minimum amount of token that must be received for the transaction not to revert.
     * @param amountETHMin The minimum amount of ETH that must be received for the transaction not to revert.
     * @param to Recipient of the underlying assets.
     * @param deadline Unix timestamp after which the transaction will revert.
     * @custom:requirement There must be enough liquidity for both token amounts to be removed.
     * @return amountETH The amount of ETH received.
     */
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    /**
     * @notice See {ISomaSwapRouter-removeLiquidityETHWithPermit} - Identical but succeeds for tokens that take a fee on transfer.
     * @param token The pool token.
     * @param liquidity The amount of liquidity tokens to remove.
     * @param amountTokenMin The minimum amount of token that must be received for the transaction not to revert.
     * @param amountETHMin The minimum amount of ETH that must be received for the transaction not to revert.
     * @param to The recipient of the underlying assets.
     * @param deadline The unix timestamp after which the transaction will revert.
     * @param approveMax Whether or not the approval amount in the signature is for liquidity or uint(-1).
     * @param v The v component of the permit signature.
     * @param r The r component of the permit signature.
     * @param s The s component of the permit signature.
     * @custom:requirement There must be enough liquidity for both token amounts to be removed.
     * @return amountETH The amount of ETH received.
     */
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    /**
     * @notice See {ISomaSwapRouter-swapExactTokensForTokens} - Identical but succeeds for tokens that take a fee on transfer.
     * @param amountIn The amount of input tokens to send.
     * @param amountOutMin The minimum amount of output tokens that must be received for the transaction not to revert.
     * @param path The array of token addresses, where pools for each pair of addresses must exist and
     * have liquidity.
     * @param to The recipient of the underlying assets.
     * @param deadline The unix timestamp after which the transaction will revert.
     */
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    /**
     * @notice See {ISomaSwapRouter-swapExactETHForTokens} - Identical but succeeds for tokens that take a fee on transfer.
     * @param amountOutMin The minimum amount of output tokens that must be received for the transaction not to revert.
     * @param path The array of token addresses, where pools for each pair of addresses must exist and
     * have liquidity.
     * @param to The recipient of the output tokens.
     * @param deadline The unix timestamp after which the transaction will revert.
     * @custom:requirement The first element of `path` must be equal to the WETH address.
     * @custom:requirement The increase in balance of the last element of `path` for the `to` address must be greater than
     * or equal to `amountOutMin`.
     */
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    /**
     * @notice See {ISomaSwapRouter-swapExactTokensForETH} - Identical but succeeds for tokens that take a fee on transfer.
     * @param amountIn The amount of input tokens to send.
     * @param amountOutMin The minimum amount of output tokens that must be received for the transaction not to revert.
     * @param path The array of token addresses, where pools for each pair of addresses must exist and
     * have liquidity.
     * @param to The recipient of the output tokens.
     * @param deadline The unix timestamp after which the transaction will revert.
     * @custom:requirement The last element of `path` must be equal to the WETH address.
     * @custom:requirement The WETH balance of the router must be greater than or equal to `amountOutMin`.
     */
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/**
 * @title SOMA Swap Factory Contract.
 * @author SOMA.finance
 * @notice Interface for the {SomaSwapFactory} contract.
 */
interface ISomaSwapFactory {

    /**
     * @notice Emitted when a pair is created via `createPair()`.
     * @param token0 The address of token0.
     * @param token1 The address of token1.
     * @param pair The address of the created pair.
     */
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    /**
     * @notice Emitted when the `feeTo` address is updated from `prevFeeTo` to `newFeeTo` by `sender`.
     * @param prevFeeTo The address of the previous fee to.
     * @param prevFeeTo The address of the new fee to.
     * @param sender The address of the message sender.
     */
    event FeeToUpdated(address indexed prevFeeTo, address indexed newFeeTo, address indexed sender);

    /**
     * @notice Emitted when a router is added by `sender`.
     * @param router The address of the router added.
     * @param sender The address of the message sender.
     */
    event RouterAdded(address indexed router, address indexed sender);

    /**
     * @notice Emitted when a router is removed by `sender`.
     * @param router The address of the router removed.
     * @param sender The address of the message sender.
     */
    event RouterRemoved(address indexed router, address indexed sender);

    /**
     * @notice Returns SOMA Swap Factory Create Pair Role.
     * @dev Returns `keccak256('SomaSwapFactory.CREATE_PAIR_ROLE')`.
     */
    function CREATE_PAIR_ROLE() external pure returns (bytes32);

    /**
     * @notice Returns SOMA Swap Factory Fee Setter Role.
     * @dev Returns `keccak256('SomaSwapFactory.FEE_SETTER_ROLE')`.
     */
    function FEE_SETTER_ROLE() external pure returns (bytes32);

    /**
     * @notice Returns SOMA Swap Factory Manage Router Role.
     * @dev Returns `keccak256('SomaSwapFactory.MANAGE_ROUTER_ROLE')`.
     */
    function MANAGE_ROUTER_ROLE() external pure returns (bytes32);

    /**
     * @notice Returns the address where fees from the exchange get transferred to.
     */
    function feeTo() external view returns (address);

    /**
     * @notice Returns the address of the pair contract for tokenA and tokenB if it exists, else returns address(0).
     * @dev Returns the address of the pair for `tokenA` and `tokenB` if it exists, else returns `address(0)`.
     * @param tokenA The token0 of the pair.
     * @param tokenB The token1 of the pair.
     * @return pair The address of the pair.
     */
    function getPair(address tokenA, address tokenB) external view returns (address pair);

    /**
     * @notice Returns the nth pair created through the factory, or address(0).
     * @dev Returns the `n-th` pair (0 indexed) created through the factory, or `address(0)`.
     * @return pair The address of the pair.
     */
    function allPairs(uint) external view returns (address pair);

    /**
     * @notice Returns the total number of pairs created through the factory so far.
     */
    function allPairsLength() external view returns (uint);

    /**
     * @notice Returns True if an address is an existing router, else returns False.
     * @param target The address to return true if it an existing router, or false if it is not.
     * @return Boolean value indicating if the address is an existing router.
     */
    function isRouter(address target) external view returns (bool);

    /**
     * @notice Adds an address as a new router. A router is able to tell a pair who is swapping.
     * @param target The address to add as a new router.
     * @custom:emits RouterAdded
     * @custom:requirement The function caller must have the MANAGE_ROUTER_ROLE.
     */
    function addRouter(address target) external;

    /**
     * @notice Removes an address from the list of routers. A router is able to tell a pair who is swapping.
     * @param target The address to remove from the list of routers.
     * @custom:emits RouterRemoved
     * @custom:requirement The function caller must have the MANAGE_ROUTER_ROLE.
     */
    function removeRouter(address target) external;

    /**
     * @notice Creates a new pair.
     * @dev Creates a pair for `tokenA` and `tokenB` if one does not exist already.
     * @param tokenA The address of token0 of the pair.
     * @param tokenB The address of token1 of the pair.
     * @custom:emits PairCreated
     * @custom:requirement The function caller must have the CREATE_PAIR_ROLE.
     * @custom:requirement `tokenA` must not be equal to `tokenB`.
     * @custom:requirement `tokenA` must not be equal to `address(0)`.
     * @custom:requirement `tokenA` and `tokenB` must not be an existing pair.
     * @custom:requirement The system must not be paused.
     * @return pair The address of the pair created.
     */
    function createPair(address tokenA, address tokenB) external returns (address pair);

    /**
     * @notice Sets a new `feeTo` address.
     * @custom:emits FeeToUpdated
     * @custom:requirement The function caller must have the FEE_SETTER_ROLE.
     * @custom:requirement The system must not be paused.
     */
    function setFeeTo(address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * @title SOMA Template Factory Contract.
 * @author SOMA.finance.
 * @notice Interface of the {TemplateFactory} contract.
 */
interface ITemplateFactory {

    /**
     * @notice Emitted when a template version is created.
     * @param templateId The ID of the template added.
     * @param version The version of the template.
     * @param implementation The address of the implementation of the template.
     * @param sender The address of the message sender.
     */
    event TemplateVersionCreated(bytes32 indexed templateId, uint256 indexed version, address implementation, address indexed sender);

    /**
     * @notice Emitted when a deploy role is updated.
     * @param templateId The ID of the template with the updated deploy role.
     * @param prevRole The previous role.
     * @param newRole The new role.
     * @param sender The address of the message sender.
     */
    event DeployRoleUpdated(bytes32 indexed templateId, bytes32 prevRole, bytes32 newRole, address indexed sender);

    /**
     * @notice Emitted when a template is enabled.
     * @param templateId The ID of the template.
     * @param sender The address of the message sender.
     */
    event TemplateEnabled(bytes32 indexed templateId, address indexed sender);

    /**
     * @notice Emitted when a template is disabled.
     * @param templateId The ID of the template.
     * @param sender The address of the message sender.
     */
    event TemplateDisabled(bytes32 indexed templateId, address indexed sender);

    /**
     * @notice Emitted when a template version is deprecated.
     * @param templateId The ID of the template.
     * @param version The version of the template deprecated.
     * @param sender The address of the message sender.
     */
    event TemplateVersionDeprecated(bytes32 indexed templateId, uint256 indexed version, address indexed sender);

    /**
     * @notice Emitted when a template version is undeprecated.
     * @param templateId The ID of the template.
     * @param version The version of the template undeprecated.
     * @param sender The address of the message sender.
     */
    event TemplateVersionUndeprecated(bytes32 indexed templateId, uint256 indexed version, address indexed sender);

    /**
     * @notice Emitted when a template is deployed.
     * @param instance The instance of the deployed template.
     * @param templateId The ID of the template.
     * @param version The version of the template.
     * @param args The abi-encoded constructor arguments.
     * @param functionCalls The abi-encoded function calls.
     * @param sender The address of the message sender.
     */
    event TemplateDeployed(address indexed instance, bytes32 indexed templateId, uint256 version, bytes args, bytes[] functionCalls, address indexed sender);

    /**
     * @notice Emitted when a template is cloned.
     * @param instance The instance of the deployed template.
     * @param templateId The ID of the template.
     * @param version The version of the template.
     * @param functionCalls The abi-encoded function calls.
     * @param sender The address of the message sender.
     */
    event TemplateCloned(address indexed instance, bytes32 indexed templateId, uint256 version, bytes[] functionCalls, address indexed sender);

    /**
     * @notice Emitted when a template function is called.
     * @param target The address of the target contract.
     * @param data The abi-encoded data.
     * @param result The abi-encoded result.
     * @param sender The address of the message sender.
     */
    event FunctionCalled(address indexed target, bytes data, bytes result, address indexed sender);

    /**
     * @notice Structure of a template version.
     * @param exists True if the version exists, False if it does not.
     * @param deprecated True if the version is deprecated, False if it is not.
     * @param implementation The address of the version's implementation.
     * @param creationCode The abi-encoded creation code.
     * @param totalParts The total number of parts of the version.
     * @param partsUploaded The number of parts uploaded.
     * @param instances The array of instances.
     */
    struct Version {
        bool deprecated;
        address implementation;
        bytes creationCode;
        uint256 totalParts;
        uint256 partsUploaded;
        address[] instances;
    }

    /**
     * @notice Structure of a template.
     * @param disabled Boolean value indicating if the template is enabled.
     * @param latestVersion The latest version of the template.
     * @param deployRole The deployer role of the template.
     * @param version The versions of the template.
     * @param instances The instances of the template.
     */
    struct Template {
        bool disabled;
        bytes32 deployRole;
        Version[] versions;
        address[] instances;
    }

    /**
     * @notice Structure of deployment information.
     * @param exists Boolean value indicating if the deployment information exists.
     * @param templateId The id of the template.
     * @param version The version of the template.
     * @param args The abi-encoded arguments.
     * @param functionCalls The abi-encoded function calls.
     * @param cloned Boolean indicating if the deployment information is cloned.
     */
    struct DeploymentInfo {
        bool exists;
        uint64 block;
        uint64 timestamp;
        address sender;
        bytes32 templateId;
        uint256 version;
        bytes args;
        bytes[] functionCalls;
        bool cloned;
    }

    /**
     * @notice Initializer of the contract.
     */
    function initialize() external;

    /**
     * @notice Returns a version of a template.
     * @param templateId The id of the template to return the version of.
     * @param version The version of the template to be returned.
     * @return The version of the template.
     */
    function version(bytes32 templateId, uint256 version) external view returns (Version memory);

    /**
     * @notice Returns the latest version of a template.
     * @param templateId The id of the template to return the latest version of.
     * @return The latest version of the template.
     */
    function latestVersion(bytes32 templateId) external view returns (uint256);

    /**
     * @notice Returns the instances of a template.
     * @param templateId The id of the template to return the latest instance of.
     * @return The instances of the template.
     */
    function templateInstances(bytes32 templateId) external view returns (address[] memory);

    /**
    * @notice Returns the deployment information of an instance.
     * @param instance The instance of the template to return deployment information of.
     * @return The deployment information of the template.
     */
    function deploymentInfo(address instance) external view returns (DeploymentInfo memory);

    /**
     * @notice Returns the deploy role of a template.
     * @param templateId The id of the template to return the deploy role of.
     * @return The deploy role of the template.
     */
    function deployRole(bytes32 templateId) external view returns (bytes32);

    /**
     * @notice Returns True if an instance has been deployed by the template factory, else returns False.
     * @dev Returns `true` if `instance` has been deployed by the template factory, else returns `false`.
     * @param instance The instance of the template to return True for, if it has been deployed by the factory, else False.
     * @return Boolean value indicating if the instance has been deployed by the template factory.
     */
    function deployedByFactory(address instance) external view returns (bool);

    /**
     * @notice Uploads a new template and returns True.
     * @param templateId The id of the template to upload.
     * @param initialPart The initial part to upload.
     * @param totalParts The number of total parts of the template.
     * @param implementation The address of the implementation of the template.
     * @custom:emits TemplateVersionCreated
     * @custom:requirement The length of `initialPart` must be greater than zero.
     */
    function uploadTemplate(bytes32 templateId, bytes memory initialPart, uint256 totalParts, address implementation) external returns (bool);

    /**
     * @notice Uploads a part of a template.
     * @param templateId The id of the template to upload a part to.
     * @param version The version of the template to upload a part to.
     * @param part The part to upload to the template.
     * @custom:requirement The length of part must be greater than zero.
     * @custom:requirement The version of the template must already exist.
     * @custom:requirement The version's number of parts uploaded must be less than the version's total number of parts.
     * @return Boolean value indicating if the operation was successful.
     */
    function uploadTemplatePart(bytes32 templateId, uint256 version, bytes memory part) external returns (bool);

    /**
     * @notice Updates the deploy role of a template.
     * @param templateId The id of the template to update the deploy role for.
     * @param deployRole The deploy role to update to.
     * @custom:emits DeployRoleUpdated
     * @custom:requirement The template's existing deploy role cannot be equal to `deployRole`.
     * @return Boolean value indicating if the operation was successful.
     */
    function updateDeployRole(bytes32 templateId, bytes32 deployRole) external returns (bool);

    /**
     * @notice Disables a template and returns True.
     * @dev Disables a template and returns `true`.
     * @param templateId The id of the template to disable.
     * @custom:emits TemplateDisabled
     * @custom:requirement The template must be enabled when the function call is made.
     * @return Boolean value indicating if the operation was successful.
     */
    function disableTemplate(bytes32 templateId) external returns (bool);

    /**
     * @notice Enables a template and returns True.
     * @dev Enables a template and returns `true`.
     * @param templateId The id of the template to enable.
     * @custom:emits TemplateEnabled
     * @custom:requirement The template must be disabled when the function call is made.
     * @return Boolean value indicating if the operation was successful.
     */
    function enableTemplate(bytes32 templateId) external returns (bool);

    /**
     * @notice Deprecates a version of a template. A deprecated template version cannot be deployed.
     * @param templateId The id of the template to deprecate the version for.
     * @param version The version of the template to deprecate.
     * @custom:emits TemplateVersionDeprecated
     * @custom:requirement The version must already exist.
     * @custom:requirement The version must not be deprecated already.
     * @return Boolean value indicating if the operation was successful.
     */
    function deprecateVersion(bytes32 templateId, uint256 version) external returns (bool);

    /**
     * @notice Undeprecates a version of a template and returns True.
     * @param templateId The id of the template to undeprecate a version for.
     * @param version The version of a template to undeprecate.
     * @custom:emits TemplateVersionUndeprecated
     * @custom:requirement The version must be deprecated already.
     * @return Boolean value indicating if the operation was successful.
     */
    function undeprecateVersion(bytes32 templateId, uint256 version) external returns (bool);

    /**
     * @notice Returns the Init Code Hash.
     * @dev Returns the keccak256 hash of `templateId`, `version` and `args`.
     * @param templateId The id of the template to return the init code hash of.
     * @param args The abi-encoded constructor arguments.
     * @return The abi-encoded init code hash.
     */
    function initCodeHash(bytes32 templateId, uint256 version, bytes memory args) external view returns (bytes32);

    /**
     * @notice Overloaded predictDeployAddress function.
     * @dev See {ITemplateFactory-predictDeployAddress}.
     * @param templateId The id of the template to predict the deploy address for.
     * @param version The version of the template to predict the deploy address for.
     * @param args The abi-encoded constructor arguments.
     */
    function predictDeployAddress(bytes32 templateId, uint256 version, bytes memory args, bytes32 salt) external view returns (address);

    /**
     * @notice Predict the clone address.
     * @param templateId The id of the template to predict the clone address for.
     * @param version The version of the template to predict the clone address for.
     * @return The predicted clone address.
     */
    function predictCloneAddress(bytes32 templateId, uint256 version, bytes32 salt) external view returns (address);

    /**
     * @notice Deploys a version of a template.
     * @param templateId The id of the template to deploy.
     * @param version The version of the template to deploy.
     * @param args The abi-encoded constructor arguments.
     * @param functionCalls The abi-encoded function calls.
     * @param salt The unique hash to identify the contract.
     * @custom:emits TemplateDeployed
     * @custom:requirement The version's number of parts must be equal to the version's number of parts uploaded.
     * @custom:requirement The length of the version's creation code must be greater than zero.
     * @return instance The instance of the deployed template.
     */
    function deployTemplate(bytes32 templateId, uint256 version, bytes memory args, bytes[] memory functionCalls, bytes32 salt) external returns (address instance);

    /**
     * @notice Clones a version of a template.
     * @param templateId The id of the template to clone.
     * @param version The version of the template to clone.
     * @param functionCalls The abi-encoded function calls.
     * @param salt The unique hash to identify the contract.
     * @custom:emits TemplateCloned
     * @custom:requirement The version's implementation must not equal `address(0)`.
     * @return instance The address of the cloned template instance.
     */
    function cloneTemplate(bytes32 templateId, uint256 version, bytes[] memory functionCalls, bytes32 salt) external returns (address instance);

    /**
     * @notice Calls a function on the target contract.
     * @param target The target address of the function call.
     * @param data Miscalaneous data associated with the transfer.
     * @custom:emits FunctionCalled
     * @return result The result of the function call.
     */
    function functionCall(address target, bytes memory data) external returns (bytes memory result);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./ILockdrop.sol";

/**
 * @title SOMA Lockdrop Factory Contract.
 * @author SOMA.finance.
 * @notice A factory that produces Lockdrop contracts.
 */
interface ILockdropFactory {

    /**
     * @notice Emitted when a Lockdrop is created.
     * @param id The ID of the Lockdrop.
     * @param asset The delegation asset of the Lockdrop.
     * @param instance The address of the created Lockdrop.
     */
    event LockdropCreated(uint256 id, address asset, address instance);

    /**
     * @notice The Lockdrop's CREATE_ROLE.
     * @dev Returns keccak256('Lockdrop.CREATE_ROLE').
     */
    function CREATE_ROLE() external pure returns (bytes32);

    /**
     * @notice Creates a Lockdrop instance.
     * @param asset The address of the delegation asset.
     * @param withdrawTo The address that delegated assets will be withdrawn to.
     * @param dateConfig The date configuration of the Lockdrop.
     * @custom:emits LockdropCreated
     */
    function create(
        address asset,
        address withdrawTo,
        ILockdrop.DateConfig calldata dateConfig
    ) external;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

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
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
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
        return _values(set._inner);
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
     * @dev Returns the number of values on the set. O(1).
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/**
 * @title SOMA Lockdrop Contract.
 * @author SOMA.finance
 * @notice A fund raising contract for bootstrapping DEX liquidity pools.
 */
interface ILockdrop {

    /**
     * @notice Emitted when the {DelegationConfig} is updated.
     * @param prevConfig The previous delegation configuration.
     * @param newConfig The new delegation configuration.
     * @param sender The message sender that triggered the event.
     */
    event DelegationConfigUpdated(DelegationConfig prevConfig, DelegationConfig newConfig, address indexed sender);

    /**
     * @notice Emitted when the {withdrawTo} address is updated.
     * @param prevTo The previous withdraw to address.
     * @param newTo The new withdraw to address.
     * @param sender The message sender that triggered the event.
     */
    event WithdrawToUpdated(address prevTo, address newTo, address indexed sender);

    /**
     * @notice Emitted when a delegation is added to a pool.
     * @param poolId The pool ID.
     * @param amount The delegation amount denominated in the delegation asset.
     * @param sender The message sender that triggered the event.
     */
    event DelegationAdded(bytes32 indexed poolId, uint256 amount, address indexed sender);

    /**
     * @notice Emitted when someone calls {moveDelegation}, transferring their delegation to a different pool.
     * @param fromPoolId The pool ID of the source pool.
     * @param toPoolId The pool ID of the destination pool.
     * @param amount The amount of the delegation asset to move.
     * @param sender TThe message sender that triggered the event.
     */
    event DelegationMoved(bytes32 indexed fromPoolId, bytes32 indexed toPoolId, uint256 amount, address indexed sender);

    /**
     * @notice Emitted when the {DateConfig} is updated.
     * @param prevDateConfig The previous date configuration.
     * @param newDateConfig The new date configuration.
     * @param sender The message sender that triggered the event.
     */
    event DatesUpdated(DateConfig prevDateConfig, DateConfig newDateConfig, address indexed sender);

    /**
     * @notice Emitted when the {Pool} is updated.
     * @param poolId The pool ID.
     * @param requiredPrivileges The new required privileges.
     * @param enabled Boolean indicating if the pool is enabled.
     * @param sender The message sender that triggered the event.
     */
    event PoolUpdated(bytes32 indexed poolId, bytes32 requiredPrivileges, bool enabled, address indexed sender);

    /**
     * @notice Date Configuration structure. These phases represent the 3 phases that the lockdrop
     * will go through, and will change the functionality of the lockdrop at each phase.
     * @param phase1 The unix timestamp for the start of phase1.
     * @param phase2 The unix timestamp for the start of phase2.
     * @param phase3 The unix timestamp for the start of phase3.
     */
    struct DateConfig {
        uint48 phase1;
        uint48 phase2;
        uint48 phase3;
    }

    /**
     * @notice Pool structure. Each pool will bootstrap liquidity for an upcoming DEX pair.
     * E.g: sTSLA/USDC
     * @param enabled Boolean indicating if the pool is enabled.
     * @param requiredPrivileges The required privileges of the pool.
     * @param balances The mapping of user addresses to delegation balances.
     */
    struct Pool {
        bool enabled;
        bytes32 requiredPrivileges;
        mapping(address => uint256) balances;
    }

    /**
     * @notice Delegation Configuration structure. Each user will specify their own Delegation Configuration.
     * @param percentLocked The percentage of user rewards to delegate to phase2.
     * @param lockDuration The lock duration of the user rewards.
     */
    struct DelegationConfig {
        uint8 percentLocked;
        uint8 lockDuration;
    }

    /**
     * @notice Returns the Lockdrop Global Admin Role.
     * @dev Equivalent to keccak256('Lockdrop.GLOBAL_ADMIN_ROLE').
     */
    function GLOBAL_ADMIN_ROLE() external pure returns (bytes32);

    /**
     * @notice Returns the Lockdrop Local Admin Role.
     */
    function LOCAL_ADMIN_ROLE() external view returns (bytes32);

    /**
     * @notice Returns the ID of the Lockdrop.
     */
    function id() external view returns (uint256);

    /**
     * @notice The address of the Lockdrop's delegation asset.
     */
    function asset() external view returns (address);

    /**
     * @notice The date configuration of the Lockdrop.
     */
    function dateConfig() external view returns (DateConfig memory);

    /**
     * @notice The address where the delegated funds will be withdrawn to.
     */
    function withdrawTo() external view returns (address);

    /**
     * @notice Initialize function for the Lockdrop contract.
     * @param _id The ID of the Lockdrop.
     * @param _asset The address of the delegation asset for the pool.
     * @param _withdrawTo The withdrawTo address for the pool.
     * @param _dateConfig The date configuration for the Lockdrop.
     */
    function initialize(
        uint256 _id,
        address _asset,
        address _withdrawTo,
        DateConfig calldata _dateConfig
    ) external;

    /**
     * @notice Updates the Lockdrop's date configuration.
     * @param newConfig The updated date configuration.
     * @custom:emits DatesUpdated
     */
    function updateDateConfig(DateConfig calldata newConfig) external;

    /**
     * @notice Sets the `withdrawTo` address.
     * @param account The updated `withdrawTo` address.
     * @custom:emits WithdrawToUpdated
     */
    function setWithdrawTo(address account) external;

    /**
     * @notice Returns the delegation balance of an account, given a pool ID.
     * @param poolId The poolId to return the account's balance of.
     * @param account The account to return the balance of.
     * @return The delegation balance of `account` for the `poolId` pool.
     */
    function balanceOf(bytes32 poolId, address account) external view returns (uint256);

    /**
     * @notice Returns the delegation configuration of an account.
     * @param account The account to return the delegation configuration of.
     * @return The delegation configuration of the Lockdrop.
     */
    function delegationConfig(address account) external view returns (DelegationConfig memory);

    /**
     * @notice Returns a boolean indicating if a pool is enabled.
     * @param poolId The pool ID to check the enabled status of.
     * @return True if the pool is enabled, False if the pool is disabled.
     */
    function enabled(bytes32 poolId) external view returns (bool);

    /**
     * @notice Returns the required privileges of the pool. These privileges are required in order to
     * delegate.
     * @param poolId The pool ID to check the enabled status of.
     * @return The required privileges of the pool.
     */
    function requiredPrivileges(bytes32 poolId) external view returns (bytes32);

    /**
     * @notice Updates the lockdrop pool parameters.
     * @param poolId The ID of the pool to update.
     * @param requiredPrivileges The updated required privileges of the pool.
     * @param enabled The updated enabled or disabled state of the pool.
     * @custom:emits PoolUpdated
     * @custom:requirement The function caller must have the GLOBAL_ADMIN_ROLE or LOCAL_ADMIN_ROLE.
     */
    function updatePool(bytes32 poolId, bytes32 requiredPrivileges, bool enabled) external;

    /**
     * @notice Withdraws tokens from the Lockdrop contract to the `withdrawTo` address.
     * @param amount The amount of tokens to be withdrawn.
     * @custom:requirement The function caller must have the GLOBAL_ADMIN_ROLE or LOCAL_ADMIN_ROLE.
     */
    function withdraw(uint256 amount) external;

    /**
     * @notice Moves the accounts' delegated tokens from one pool to another.
     * @param fromPoolId The ID of the pool that the delegation will be moved from.
     * @param toPoolId The ID of the pool that the delegation will be moved to.
     * @param amount The amount of tokens to be moved.
     * @custom:emits DelegationMoved
     * @custom:requirement `fromPoolId` must not be equal to `toPoolId`.
     * @custom:requirement The Lockdrop's `phase1` must have started already.
     * @custom:requirement The Lockdrop's `phase2` must not have ended yet.
     * @custom:requirement `amount` must be greater than zero.
     * @custom:requirement The `fromPoolId` pool must be enabled.
     * @custom:requirement The `toPoolId` pool must be enabled.
     * @custom:requirement The delegation balance of the caller for the `fromPoolId` pool must be greater than
     * or equal to `amount`.
     * @custom:requirement The function caller must have the required privileges of the `fromPoolId` pool.
     * @custom:requirement The function caller must have the required privileges of the `toPoolId` pool.
     */
    function moveDelegation(bytes32 fromPoolId, bytes32 toPoolId, uint256 amount) external;

    /**
     * @notice Delegates tokens to the a specific pool.
     * @param poolId The ID of the pool to receive the delegation.
     * @param amount The amount of tokens to be delegated.
     * @custom:emits DelegationAdded
     * @custom:requirement `amount` must be greater than zero.
     * @custom:requirement The `poolId` pool must be enabled.
     * @custom:requirement The `poolId` pool's phase1 must have started already.
     * @custom:requirement The `poolId` pool's phase2 must not have ended yet.
     * @custom:requirement The function caller must have the `poolId` pool's required privileges.
     */
    function delegate(bytes32 poolId, uint256 amount) external;

    /**
     * @notice Updates the delegation configuration of an account.
     * @param newConfig The updated delegation configuration of the account.
     * @custom:emits DelegationConfigUpdated
     * @custom:requirement The ``newConfig``'s percent locked must be a valid percentage.
     * @custom:requirement The Lockdrop's phase1 must have started already.
     * @custom:requirement Given the Lockdrop's phase2 has ended, ``newConfig``'s percent locked must be
     * greater than the existing percent locked for the account.
     * @custom:requirement Given the Lockdrop's phase2 has ended, ``newConfig``'s lock duration must be equal
     * to the existing lock duration for the account.
     */
    function updateDelegationConfig(DelegationConfig calldata newConfig) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/**
 * @title SOMA Seizable Security Contract.
 * @author SOMA.finance.
 * @notice Interface of the {SeizableSecurity} contract.
 */
interface ISeizableSecurity {

    /**
     * @notice Emitted after a token is seized.
     * @param operator The address of the operator.
     * @param from The address that has had tokens seized from.
     * @param to The seize to address that receives seized tokens.
     * @param value The amount of tokens seized.
     * @param userData The additional user data associated with the seize transaction.
     * @param operatorData The additional operator data associated with the seize transaction.
     */
    event Seized(address indexed operator, address indexed from, address indexed to, uint256 value, bytes userData, bytes operatorData);

    /**
     * @notice Overloaded seize function.
     * @param tokenHolder The account to seize tokens from.
     * @param amount The amount of tokens to seize from `tokenHolder`.
     * @custom:emits Seized
     * @custom:requirement The message sender must have the GLOBAL_SEIZE_ROLE or LOCAL_SEIZE_ROLE.
     */
    function seize(address tokenHolder, uint256 amount) external;

    /**
     * @notice Seizes tokens from an account.
     * @param tokenHolder The account to seize tokens from.
     * @param amount The amount of tokens to seize from `tokenHolder`.
     * @param userData The additional user data associated with the seize transaction.
     * @param operatorData The additional operator data associated with the seize transaction.
     * @custom:emits Seized
     * @custom:requirement The message sender must have the GLOBAL_SEIZE_ROLE or LOCAL_SEIZE_ROLE.
     */
    function seize(address tokenHolder, uint256 amount, bytes memory userData, bytes memory operatorData) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/**
 * @title SOMA Mintable Security Contract.
 * @author SOMA.finance.
 * @notice Interface of the {MintableSecurity} contract.
 */
interface IMintableSecurity {

    /**
     * @notice Overloaded mint function.
     * @param amount The amount of tokens to mint.
     */
    function mint(uint256 amount) external;

    /**
     * @notice Mints a mintable security token.
     * @param amount The amount of tokens to mint.
     * @param userData Extra user related data to forward to the mint function.
     * @param operatorData Extra operator data to forward to the mint function.
     */
    function mint(uint256 amount, bytes memory userData, bytes memory operatorData) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC777/ERC777Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "./IERC777PermitUpgradeable.sol";

/**
 * @notice Implementation of the {IERC777PermitUpgradeable} interface. This is based on the OpenZeppelin's ERC777PermitUpgradeable contract.
 */
abstract contract ERC777PermitUpgradeable is IERC777PermitUpgradeable, ERC777Upgradeable, EIP712Upgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    mapping(address => CountersUpgradeable.Counter) private _nonces;

    bytes32 private _PERMIT_TYPEHASH;

    /**
     * @notice Initializer for extended contracts.
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     * @param name The name of the token.
     */
    function __ERC777Permit_init(string memory name) internal onlyInitializing {
        __EIP712_init_unchained(name, "1");
        __ERC777Permit_init_unchained();
    }

    /**
     * @notice Unchained initializer.
     */
    function __ERC777Permit_init_unchained() internal onlyInitializing {
        _PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    }

    /**
     * @inheritdoc IERC777PermitUpgradeable
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
        require(block.timestamp <= deadline, "ERC777Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSAUpgradeable.recover(hash, v, r, s);
        require(signer == owner, "ERC777Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @inheritdoc IERC777PermitUpgradeable
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @inheritdoc IERC777PermitUpgradeable
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @notice "Consume a nonce": return the current value and increment.
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        CountersUpgradeable.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (governance/utils/IVotes.sol)
pragma solidity ^0.8.0;

/**
 * @dev Common interface for {ERC20Votes}, {ERC721Votes}, and other {Votes}-enabled contracts.
 *
 * _Available since v4.5._
 */
interface IVotesUpgradeable {
    /**
     * @dev Emitted when an account changes their delegate.
     */
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /**
     * @dev Emitted when a token transfer or delegate change results in changes to a delegate's number of votes.
     */
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    /**
     * @dev Returns the current amount of votes that `account` has.
     */
    function getVotes(address account) external view returns (uint256);

    /**
     * @dev Returns the amount of votes that `account` had at the end of a past block (`blockNumber`).
     */
    function getPastVotes(address account, uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the total supply of votes available at the end of a past block (`blockNumber`).
     *
     * NOTE: This value is the sum of all available votes, which is not necessarily the sum of all delegated votes.
     * Votes that have not been delegated are still part of total supply, even though they would not participate in a
     * vote.
     */
    function getPastTotalSupply(uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the delegate that `account` has chosen.
     */
    function delegates(address account) external view returns (address);

    /**
     * @dev Delegates votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) external;

    /**
     * @dev Delegates votes from signer to `delegatee`.
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/SafeCast.sol)

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
library SafeCastUpgradeable {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
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
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
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
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
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
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
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
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
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
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
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
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
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
     *
     * _Available since v2.5._
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
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
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
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248) {
        require(value >= type(int248).min && value <= type(int248).max, "SafeCast: value doesn't fit in 248 bits");
        return int248(value);
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240) {
        require(value >= type(int240).min && value <= type(int240).max, "SafeCast: value doesn't fit in 240 bits");
        return int240(value);
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232) {
        require(value >= type(int232).min && value <= type(int232).max, "SafeCast: value doesn't fit in 232 bits");
        return int232(value);
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224) {
        require(value >= type(int224).min && value <= type(int224).max, "SafeCast: value doesn't fit in 224 bits");
        return int224(value);
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216) {
        require(value >= type(int216).min && value <= type(int216).max, "SafeCast: value doesn't fit in 216 bits");
        return int216(value);
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208) {
        require(value >= type(int208).min && value <= type(int208).max, "SafeCast: value doesn't fit in 208 bits");
        return int208(value);
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200) {
        require(value >= type(int200).min && value <= type(int200).max, "SafeCast: value doesn't fit in 200 bits");
        return int200(value);
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192) {
        require(value >= type(int192).min && value <= type(int192).max, "SafeCast: value doesn't fit in 192 bits");
        return int192(value);
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184) {
        require(value >= type(int184).min && value <= type(int184).max, "SafeCast: value doesn't fit in 184 bits");
        return int184(value);
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176) {
        require(value >= type(int176).min && value <= type(int176).max, "SafeCast: value doesn't fit in 176 bits");
        return int176(value);
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168) {
        require(value >= type(int168).min && value <= type(int168).max, "SafeCast: value doesn't fit in 168 bits");
        return int168(value);
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160) {
        require(value >= type(int160).min && value <= type(int160).max, "SafeCast: value doesn't fit in 160 bits");
        return int160(value);
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152) {
        require(value >= type(int152).min && value <= type(int152).max, "SafeCast: value doesn't fit in 152 bits");
        return int152(value);
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144) {
        require(value >= type(int144).min && value <= type(int144).max, "SafeCast: value doesn't fit in 144 bits");
        return int144(value);
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136) {
        require(value >= type(int136).min && value <= type(int136).max, "SafeCast: value doesn't fit in 136 bits");
        return int136(value);
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
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120) {
        require(value >= type(int120).min && value <= type(int120).max, "SafeCast: value doesn't fit in 120 bits");
        return int120(value);
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112) {
        require(value >= type(int112).min && value <= type(int112).max, "SafeCast: value doesn't fit in 112 bits");
        return int112(value);
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104) {
        require(value >= type(int104).min && value <= type(int104).max, "SafeCast: value doesn't fit in 104 bits");
        return int104(value);
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96) {
        require(value >= type(int96).min && value <= type(int96).max, "SafeCast: value doesn't fit in 96 bits");
        return int96(value);
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88) {
        require(value >= type(int88).min && value <= type(int88).max, "SafeCast: value doesn't fit in 88 bits");
        return int88(value);
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80) {
        require(value >= type(int80).min && value <= type(int80).max, "SafeCast: value doesn't fit in 80 bits");
        return int80(value);
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72) {
        require(value >= type(int72).min && value <= type(int72).max, "SafeCast: value doesn't fit in 72 bits");
        return int72(value);
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
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56) {
        require(value >= type(int56).min && value <= type(int56).max, "SafeCast: value doesn't fit in 56 bits");
        return int56(value);
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48) {
        require(value >= type(int48).min && value <= type(int48).max, "SafeCast: value doesn't fit in 48 bits");
        return int48(value);
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40) {
        require(value >= type(int40).min && value <= type(int40).max, "SafeCast: value doesn't fit in 40 bits");
        return int40(value);
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
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24) {
        require(value >= type(int24).min && value <= type(int24).max, "SafeCast: value doesn't fit in 24 bits");
        return int24(value);
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
     * - input must fit into 8 bits
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
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
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
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
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
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
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
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSAUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
 *
 * @custom:storage-size 52
 */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

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
    function __EIP712_init(string memory name, string memory version) internal onlyInitializing {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal onlyInitializing {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
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
        return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal virtual view returns (bytes32) {
        return _HASHED_VERSION;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
library CountersUpgradeable {
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

pragma solidity ^0.8.9;

/**
 * @title SOMA IERC777PermitUpgradeable Guard Contract.
 * @author SOMA.finance.
 * @notice Interface of the {ERC777PermitUpgradeable} contract.
 * This is based on the OpenZeppelin's ERC777PermitUpgradeable contract.
 */
interface IERC777PermitUpgradeable {

    /**
     * @notice Update ``sender``'s allowance over ``owner``'s tokens to `value` with a signature.
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     * @param owner The owner of the tokens to create a signature.
     * @param spender The spender to increase the token spending allowance of.
     * @param value The amount of tokens to approve.
     * @param deadline The timestamp deadline for the approval.
     * @param v The v component of the signature.
     * @param r The r component of the signature.
     * @param s The s component of the signature.
     * @custom:emits Approval
     * @custom:requirement `spender` cannot be the zero address.
     * @custom:requirement `deadline` must be a timestamp in the future.
     * @custom:requirement `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * @custom:requirement `the signature must use ``owner``'s current nonce (see {nonces}).
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
     * @notice Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     * @dev Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     * @param owner The address of the token owner.
     * @return The nonce for `owner`.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @notice Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}