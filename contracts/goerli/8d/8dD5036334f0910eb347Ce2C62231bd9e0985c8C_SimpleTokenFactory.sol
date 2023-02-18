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

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../interfaces/IERC20.sol";

contract SimpleToken is
    Context,
    IERC20,
    IERC20Mintable,
    IERC20Pegged,
    IERC20MetadataChangeable
{
    // pre-defined state
    bytes32 internal _symbol; // 0
    bytes32 internal _name; // 1
    address public owner; // 2

    // internal state
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowances;

    uint256 internal _totalSupply;
    uint256 internal _originChain;
    address internal _originAddress;

    function name() public view returns (string memory) {
        return bytes32ToString(_name);
    }

    function changeName(bytes32 newVal) external override onlyOwner {
        emit NameChanged(name(), bytes32ToString(newVal));
        _name = newVal;
    }

    function symbol() public view returns (string memory) {
        return bytes32ToString(_symbol);
    }

    function changeSymbol(bytes32 newVal) external override onlyOwner {
        emit SymbolChanged(symbol(), bytes32ToString(newVal));
        _symbol = newVal;
    }

    function bytes32ToString(bytes32 _bytes32)
        internal
        pure
        returns (string memory)
    {
        if (_bytes32 == 0) {
            return new string(0);
        }
        uint8 cntNonZero = 0;
        for (uint8 i = 16; i > 0; i >>= 1) {
            if (_bytes32[cntNonZero + i] != 0) cntNonZero += i;
        }
        string memory result = new string(cntNonZero + 1);
        assembly {
            mstore(add(result, 0x20), _bytes32)
        }
        return result;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount, true);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount, true);
        return true;
    }

    function increaseAllowance(address spender, uint256 amount)
        public
        virtual
        returns (bool)
    {
        _increaseAllowance(_msgSender(), spender, amount, true);
        return true;
    }

    function decreaseAllowance(address spender, uint256 amount)
        public
        virtual
        returns (bool)
    {
        _decreaseAllowance(_msgSender(), spender, amount, true);
        return true;
    }

    function chargeFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external virtual override onlyOwner returns (bool) {
        _transfer(sender, recipient, amount, true);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount, true);
        _decreaseAllowance(sender, _msgSender(), amount, true);
        return true;
    }

    function _increaseAllowance(
        address owner,
        address spender,
        uint256 amount,
        bool emitEvent
    ) internal {
        require(owner != address(0));
        require(spender != address(0));
        _allowances[owner][spender] += amount;
        if (emitEvent) {
            emit Approval(owner, spender, _allowances[owner][spender]);
        }
    }

    function _decreaseAllowance(
        address owner,
        address spender,
        uint256 amount,
        bool emitEvent
    ) internal {
        require(owner != address(0));
        require(spender != address(0));
        _allowances[owner][spender] -= amount;
        if (emitEvent) {
            emit Approval(owner, spender, _allowances[owner][spender]);
        }
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount,
        bool emitEvent
    ) internal {
        require(owner != address(0));
        require(spender != address(0));
        _allowances[owner][spender] = amount;
        if (emitEvent) {
            emit Approval(owner, spender, amount);
        }
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount,
        bool emitEvent
    ) internal {
        require(sender != address(0));
        require(recipient != address(0));
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        if (emitEvent) {
            emit Transfer(sender, recipient, amount);
        }
    }

    function mint(address account, uint256 amount)
        public
        virtual
        override
        onlyOwner
    {
        require(account != address(0));
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function burn(address account, uint256 amount)
        public
        virtual
        override
        onlyOwner
    {
        require(account != address(0));
        _balances[account] -= amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    modifier emptyOwner() {
        require(owner == address(0x00));
        _;
    }

    function initAndObtainOwnership(
        bytes32 symbol,
        bytes32 name,
        uint256 originChain,
        address originAddress
    ) public emptyOwner {
        owner = msg.sender;
        _symbol = symbol;
        _name = name;
        _originChain = originChain;
        _originAddress = originAddress;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function getOrigin() public view override returns (uint256, address) {
        return (_originChain, _originAddress);
    }
}

contract SimpleTokenFactory {
    address private _template;

    constructor() {
        _template = SimpleTokenFactoryUtils.deploySimpleTokenTemplate(this);
    }

    function getImplementation() public view returns (address) {
        return _template;
    }
}

library SimpleTokenFactoryUtils {
    bytes32 internal constant SIMPLE_TOKEN_TEMPLATE_SALT =
        keccak256("SimpleTokenTemplateV3");

    bytes internal constant SIMPLE_TOKEN_TEMPLATE_BYTECODE =
        hex"608060405234801561001057600080fd5b50610c03806100206000396000f3fe608060405234801561001057600080fd5b50600436106101215760003560e01c806370a08231116100ad5780639dc29fac116100715780639dc29fac1461026b578063a457c2d71461027e578063a9059cbb14610291578063dd62ed3e146102a4578063df1f29ee146102dd57600080fd5b806370a08231146101e9578063898855ed146102125780638da5cb5b1461022557806394bfed881461025057806395d89b411461026357600080fd5b806323b872dd116100f457806323b872dd1461018e578063313ce567146101a157806339509351146101b057806340c10f19146101c35780636083f0c8146101d657600080fd5b806306fdde0314610126578063095ea7b31461014457806318160ddd146101675780631ad8fde614610179575b600080fd5b61012e610300565b60405161013b91906109dc565b60405180910390f35b610157610152366004610a12565b610312565b604051901515815260200161013b565b6005545b60405190815260200161013b565b61018c610187366004610a3c565b61032b565b005b61015761019c366004610a55565b61038f565b6040516012815260200161013b565b6101576101be366004610a12565b6103b5565b61018c6101d1366004610a12565b6103c4565b6101576101e4366004610a55565b610478565b61016b6101f7366004610a91565b6001600160a01b031660009081526003602052604090205490565b61018c610220366004610a3c565b61049f565b600254610238906001600160a01b031681565b6040516001600160a01b03909116815260200161013b565b61018c61025e366004610aac565b610503565b61012e610554565b61018c610279366004610a12565b610561565b61015761028c366004610a12565b61060f565b61015761029f366004610a12565b61061e565b61016b6102b2366004610aeb565b6001600160a01b03918216600090815260046020908152604080832093909416825291909152205490565b600654600754604080519283526001600160a01b0390911660208301520161013b565b606061030d60015461062d565b905090565b60006103213384846001610707565b5060015b92915050565b6002546001600160a01b0316331461034257600080fd5b7fd7ad744cc76ebad190995130eec8ba506b3605612d23b5b9cef8e27f14d138b461036b610554565b6103748361062d565b604051610382929190610b1e565b60405180910390a1600055565b600061039e84848460016107af565b6103ab843384600161087a565b5060019392505050565b60006103213384846001610939565b6002546001600160a01b031633146103db57600080fd5b6001600160a01b0382166103ee57600080fd5b80600560008282546104009190610b62565b90915550506001600160a01b0382166000908152600360205260408120805483929061042d908490610b62565b90915550506040518181526001600160a01b038316906000907fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef906020015b60405180910390a35050565b6002546000906001600160a01b0316331461049257600080fd5b6103ab84848460016107af565b6002546001600160a01b031633146104b657600080fd5b7f6c20b91d1723b78732eba64ff11ebd7966a6e4af568a00fa4f6b72c20f58b02a6104df610300565b6104e88361062d565b6040516104f6929190610b1e565b60405180910390a1600155565b6002546001600160a01b03161561051957600080fd5b60028054336001600160a01b031991821617909155600094909455600192909255600655600780549092166001600160a01b03909116179055565b606061030d60005461062d565b6002546001600160a01b0316331461057857600080fd5b6001600160a01b03821661058b57600080fd5b6001600160a01b038216600090815260036020526040812080548392906105b3908490610b75565b9250508190555080600560008282546105cc9190610b75565b90915550506040518181526000906001600160a01b038416907fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef9060200161046c565b6000610321338484600161087a565b600061032133848460016107af565b6060600082900361064c57505060408051600081526020810190915290565b600060105b60ff8116156106a357836106658284610b9e565b60ff166020811061067857610678610bb7565b1a60f81b6001600160f81b03191615610698576106958183610b9e565b91505b60011c607f16610651565b5060006106b1826001610b9e565b60ff1667ffffffffffffffff8111156106cc576106cc610b88565b6040519080825280601f01601f1916602001820160405280156106f6576020820181803683370190505b506020810194909452509192915050565b6001600160a01b03841661071a57600080fd5b6001600160a01b03831661072d57600080fd5b6001600160a01b03808516600090815260046020908152604080832093871683529290522082905580156107a957826001600160a01b0316846001600160a01b03167f8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925846040516107a091815260200190565b60405180910390a35b50505050565b6001600160a01b0384166107c257600080fd5b6001600160a01b0383166107d557600080fd5b6001600160a01b038416600090815260036020526040812080548492906107fd908490610b75565b90915550506001600160a01b0383166000908152600360205260408120805484929061082a908490610b62565b909155505080156107a957826001600160a01b0316846001600160a01b03167fddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef846040516107a091815260200190565b6001600160a01b03841661088d57600080fd5b6001600160a01b0383166108a057600080fd5b6001600160a01b038085166000908152600460209081526040808320938716835292905290812080548492906108d7908490610b75565b909155505080156107a9576001600160a01b038481166000818152600460209081526040808320948816808452948252918290205491519182527f8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b92591016107a0565b6001600160a01b03841661094c57600080fd5b6001600160a01b03831661095f57600080fd5b6001600160a01b038085166000908152600460209081526040808320938716835292905290812080548492906108d7908490610b62565b6000815180845260005b818110156109bc576020818501810151868301820152016109a0565b506000602082860101526020601f19601f83011685010191505092915050565b6020815260006109ef6020830184610996565b9392505050565b80356001600160a01b0381168114610a0d57600080fd5b919050565b60008060408385031215610a2557600080fd5b610a2e836109f6565b946020939093013593505050565b600060208284031215610a4e57600080fd5b5035919050565b600080600060608486031215610a6a57600080fd5b610a73846109f6565b9250610a81602085016109f6565b9150604084013590509250925092565b600060208284031215610aa357600080fd5b6109ef826109f6565b60008060008060808587031215610ac257600080fd5b843593506020850135925060408501359150610ae0606086016109f6565b905092959194509250565b60008060408385031215610afe57600080fd5b610b07836109f6565b9150610b15602084016109f6565b90509250929050565b604081526000610b316040830185610996565b8281036020840152610b438185610996565b95945050505050565b634e487b7160e01b600052601160045260246000fd5b8082018082111561032557610325610b4c565b8181038181111561032557610325610b4c565b634e487b7160e01b600052604160045260246000fd5b60ff818116838216019081111561032557610325610b4c565b634e487b7160e01b600052603260045260246000fdfea2646970667358221220919c54b744df9df88a6cc4e600fe59ae1da5ece4a4cdef3b6e535f90469cee5d64736f6c63430008100033";

    bytes32 internal constant SIMPLE_TOKEN_TEMPLATE_HASH =
        keccak256(SIMPLE_TOKEN_TEMPLATE_BYTECODE);

    bytes4 internal constant SET_META_DATA_SIG =
        bytes4(keccak256("obtainOwnership(bytes32,bytes32)"));

    function deploySimpleTokenTemplate(SimpleTokenFactory templateFactory)
        internal
        returns (address)
    {
        /* we can use any deterministic salt here, since we don't care about it */
        bytes32 salt = SIMPLE_TOKEN_TEMPLATE_SALT;
        /* concat bytecode with constructor */
        bytes memory bytecode = SIMPLE_TOKEN_TEMPLATE_BYTECODE;
        /* deploy contract and store result in result variable */
        address result;
        assembly {
            result := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(result != address(0x00), "deploy failed");
        /* check that generated contract address is correct */
        require(
            result == simpleTokenTemplateAddress(templateFactory),
            "address mismatched"
        );
        return result;
    }

    function simpleTokenTemplateAddress(SimpleTokenFactory templateFactory)
        internal
        pure
        returns (address)
    {
        bytes32 hash = keccak256(
            abi.encodePacked(
                uint8(0xff),
                address(templateFactory),
                SIMPLE_TOKEN_TEMPLATE_SALT,
                SIMPLE_TOKEN_TEMPLATE_HASH
            )
        );
        return address(bytes20(hash << 96));
    }
}

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Mintable {
    function mint(address account, uint256 amount) external;

    function burn(address account, uint256 amount) external;

    // use for charge bridge commission before burn
    function chargeFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IERC20Pegged {
    function getOrigin() external view returns (uint256, address);
}

interface IERC20Extra {
    function name() external returns (string memory);

    function decimals() external returns (uint8);

    function symbol() external returns (string memory);
}

interface IERC20MetadataChangeable {
    event NameChanged(string prevValue, string newValue);

    event SymbolChanged(string prevValue, string newValue);

    function changeName(bytes32) external;

    function changeSymbol(bytes32) external;
}