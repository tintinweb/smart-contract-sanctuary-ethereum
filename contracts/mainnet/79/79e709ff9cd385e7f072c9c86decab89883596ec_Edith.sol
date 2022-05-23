/**
 *Submitted for verification at Etherscan.io on 2022-05-23
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.13;



interface IERC20 {
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



abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}



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
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[owner][spender];
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
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
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



contract Edith is ERC20, Ownable {
    mapping (address => uint256) private _rOwned;
    mapping (address => bool) private _isHolder;
    address[] private _holders;
    
    //mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    //recieves no reflections, transfers from are untaxed
    mapping (address => bool) private _isExcluded; 
    //recieves no reflections, all transfers are untaxed. All items on this list need to also be on _isExcluded.
    mapping (address => bool) private _isCompletelyExcluded;

    //address[] private _holders;
    address[] private _excluded;
   
    uint256 private constant MAX = 2**128 - 1;
    uint256 private constant _tTotal = 10 * 10**6 * 10**5;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _rTotalInitial = _rTotal;
    uint256 private _tFeeTotal;

    uint256 private _taxLowerBound = 0;
    uint256 private _taxUpperBound = 0;
    uint256 private constant _taxMaximum = 50; //sets the absolute max tax
    uint256 private _taxMaximumCutoff = 50; 
    bool private _rSupplyNeedsReset = false;

    string private constant _name = "Edith";
    string private constant _symbol = "EDTH";
    uint8 private constant _decimals = 5;

    constructor () ERC20("Edith", "EDTH") {
        address sender = _msgSender();
        _rOwned[sender] = _rTotal;
        _isHolder[sender] = true;
        _holders.push(sender);
        setTaxRates(2, 20);
        emit Transfer(address(0), sender, _tTotal);
    }

    function min(uint256 a, uint256 b) private pure returns(uint256) {
        if (a <= b) {
            return a;
        } else {
            return b;
        }
    }

    function setTaxRates(uint256 LB, uint256 UB) public onlyOwner returns(bool) {
        require(LB <= UB, "lower bound must be less than or equal to upper bound");
        require(UB <= _taxMaximum, "upper bound must be less than or equal to _taxMaximum");
        require(!_rSupplyNeedsReset, "the tax functionality has been permenantly disabled for this contract");
        _taxLowerBound = LB;
        _taxUpperBound = UB;
        return true;
    }

    function setTaxMaximumCutoff(uint256 cutoff) public onlyOwner returns(bool) {
        require(cutoff >= _tTotal/10, "cutoff must be >= 1/10th of the total supply");
        _taxMaximumCutoff = cutoff;
        return true;
    }

    function getTaxMaximumCutoff() public view returns(uint256) {
        return _taxMaximumCutoff;
    }

    function getTaxRates() public view returns(uint256, uint256) {
        return(_taxLowerBound, _taxUpperBound);
    }

    function getTaxableState() public view returns(bool){
        return !_rSupplyNeedsReset;
    }

    function name() public pure override returns (string memory) {
        return _name;
    }

    function symbol() public pure override returns (string memory) {
        return _symbol;
    }

    function decimals() public pure override returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function rSupply() public view returns(uint256) {
        return _rTotal;
    }

    function rOwned(address account) public view returns(uint256) {
        return _rOwned[account];
    }

    function balanceOf(address account) public view override returns (uint256) {
        // uint256 rAmount = _rOwned[account];
        // uint256 currentRate =  _getRate();
        // return rAmount/currentRate;
        return (_rOwned[account]*_tTotal)/_rTotal;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        if (!_isHolder[recipient]) {
            _isHolder[recipient] = true;
            _holders.push(recipient);
        }
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        uint256 allowed = _allowances[sender][_msgSender()];
        require(amount <= allowed, "transferring too much edith");
        _approve(sender, _msgSender(), allowed - amount);
        _transfer(sender, recipient, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public override returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public override returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
        return true;
    }

    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function isCompletelyExcluded(address account) public view returns (bool) {
        return _isCompletelyExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function excludeAccount(address account) external onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function completelyExcludeAccount(address account) external onlyOwner() {
        require(!_isCompletelyExcluded[account], "Account is already completely excluded");
        _isCompletelyExcluded[account] = true;
        // check if already on excluded list. if not, add it.
        if (!_isExcluded[account]){
            _isExcluded[account] = true;
            _excluded.push(account);
        }
    }

    function numExcluded() public view returns(uint256) {
        return _excluded.length;
    }

    function viewExcluded(uint256 n) public view returns(address) {
        require(n < _excluded.length, "n is too big");
        return _excluded[n];
    }

    function includeAccount(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already included");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                //_tOwned[account] = 0;
                _isExcluded[account] = false;
                _isCompletelyExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function _approve(address owner, address spender, uint256 amount) internal override {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override{
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");


        if (_isExcluded[sender] || _isCompletelyExcluded[recipient] || _rSupplyNeedsReset || _taxUpperBound == 0) {
            //sender excluded or both excluded, or recipient completely excluded
            _transferTaxFree(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else {
            uint256 excludedRowned = 0;
            if (!_isExcluded[sender]){
                excludedRowned += _rOwned[sender];
            }
            if (!_isExcluded[recipient]){
                excludedRowned += _rOwned[recipient];
            }
            for (uint256 i = 0; i < _excluded.length; i++){
                excludedRowned += _rOwned[_excluded[i]];
            }
            if (excludedRowned > (99*_rTotal)/100){
                _transferTaxFree(sender, recipient, amount);
            } else {
                _transferStandard(sender, recipient, amount);
            }
            
        }
    }

    //struct needed to avoid "stack too deep" compile error
    struct stackTooDeepStruct {
        uint256 n1;
        uint256 n2;
        uint256 n3;
        uint256 temp;
        uint256 a;
        uint256 b;
        uint256 c;
    }

    struct accountInfo {
        address account;
        uint256 rOwned;
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount); //, rSupply, tSupply);
        uint256 ne = numExcluded();

        uint256[] memory excludedROwned = new uint256[](ne);
        uint256 totalExcluded = 0;

        for (uint i = 0; i < ne; i++){
            excludedROwned[i] = _rOwned[_excluded[i]];
            totalExcluded += excludedROwned[i];
        }

        stackTooDeepStruct memory std;
        std.n1 = _rOwned[sender] - rAmount;
        std.n2 = _rOwned[recipient] + rTransferAmount;
        std.n3 = totalExcluded;
        std.temp = _rTotal- std.n1 - std.n2 - std.n3;

        std.a = (rFee*std.n1)/std.temp;
        std.b = (rFee*std.n2)/std.temp;
        std.c = (rFee*std.n3)/std.temp;


        _rOwned[sender] = std.n1 - std.a;
        _rOwned[recipient] = std.n2 - std.b;
        uint256 subtractedTotal = 0;
        uint256 toSubtract;
        if (totalExcluded > 0){
            for (uint i=0; i < ne; i++){
                toSubtract = (std.c*excludedROwned[i])/totalExcluded;
                _rOwned[_excluded[i]] = excludedROwned[i] - toSubtract;
                subtractedTotal += toSubtract;
            }
            //_rOwned[_excluded[ne-1]] = excludedROwned[ne-1] - (std.c - subtractedTotal);
        }
        _reflectFee(rFee + std.a + std.b + subtractedTotal, tFee);
        emit Transfer(sender, recipient, tTransferAmount);

    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount); //, rSupply, tSupply);

        uint256 ne = numExcluded();

        // for this one, excludedInfo refers to accounts *other than* the recipient.
        // otherwise, this function is the same as transferStandard.
        // i.e. the recipient is just another excluded account.
        accountInfo[] memory excludedInfo = new accountInfo[](ne - 1);
        uint256 totalExcluded = 0;

        uint256 arrayIndex = 0;
        for (uint i = 0; i < ne; i++){
            if (_excluded[i] != recipient){
                excludedInfo[arrayIndex].account = _excluded[i];
                excludedInfo[arrayIndex].rOwned = _rOwned[excludedInfo[arrayIndex].account];
                totalExcluded += excludedInfo[arrayIndex].rOwned;
                arrayIndex += 1;
            }
        }

        stackTooDeepStruct memory std;
        std.n1 = _rOwned[sender] - rAmount;
        std.n2 = _rOwned[recipient] + rTransferAmount;
        std.n3 = totalExcluded;
        std.temp = _rTotal - std.n1 - std.n2 - std.n3;

        std.a = (rFee*std.n1)/std.temp;
        std.b = (rFee*std.n2)/std.temp;
        std.c = (rFee*std.n3)/std.temp;

        _rOwned[sender] = std.n1 - std.a;
        _rOwned[recipient] = std.n2 - std.b;

        uint256 subtractedTotal = 0;
        uint256 toSubtract;
        if (totalExcluded > 0){
            for (uint i = 0; i < excludedInfo.length; i++){
                toSubtract = (std.c * excludedInfo[i].rOwned) / totalExcluded;
                _rOwned[excludedInfo[i].account] = excludedInfo[i].rOwned - toSubtract;
                subtractedTotal += toSubtract;
            }
            //_rOwned[excludedInfo[excludedInfo.length - 1].account] = excludedInfo[excludedInfo.length - 1].rOwned - (std.c - subtractedTotal);
        }
        _reflectFee(rFee + std.a + std.b + subtractedTotal, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }


    function _transferTaxFree(address sender, address recipient, uint256 tAmount) private {
        // uint256 currentRate = _rTotal / _tTotal;
        // uint256 rAmount = tAmount * currentRate;
        uint256 rAmount = (tAmount * _rTotal) / _tTotal;
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rOwned[recipient] = _rOwned[recipient] + rAmount; 
        emit Transfer(sender, recipient, tAmount);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal -= rFee;
        _tFeeTotal += tFee;
    }

    function calculateTax(uint256 tAmount) public view returns (uint256) {
        uint256 cutoffTSupply = (_tTotal * _taxMaximumCutoff) / 100;
        uint256 taxTemp = _taxLowerBound + ((_taxUpperBound - _taxLowerBound)*tAmount)/cutoffTSupply;
        return min(taxTemp, _taxUpperBound);
    }

    function _getValues(uint256 tAmount) private returns (uint256, uint256, uint256, uint256, uint256) {
        //check for rSupply depletion
        if (!_rSupplyNeedsReset) {
            if (_rTotal < 15 * _tTotal){
                _rSupplyNeedsReset = true;
            }
        }

        //calculates tax based on amount being transferred
        uint256 tax = calculateTax(tAmount); //_taxLowerBound + (_taxUpperBound - _taxLowerBound) * tAmount.div(tSupply);

        (uint256 tTransferAmount, uint256 tFee) = _getTValues(tAmount, tax);
        //uint256 currentRate =  _getRate();
        //uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee);
    }

    function _getTValues(uint256 tAmount, uint256 tax) private pure returns (uint256, uint256) {
        uint256 tFee = (tAmount * tax) / 100;
        uint256 tTransferAmount = tAmount - tFee;
        return (tTransferAmount, tFee);
    }

    function _getRValues(uint256 tAmount, uint256 tFee) private view returns (uint256, uint256, uint256) {
        uint256 rAmount = (tAmount * _rTotal) / _tTotal;
        uint256 rFee = (tFee * _rTotal) / _tTotal;
        uint256 rTransferAmount = rAmount - rFee;
        return (rAmount, rTransferAmount, rFee);
    }

    function resetRSupply() public onlyOwner returns(bool) {
        uint256 newROwned;
        uint256 totalNewROwned;
        for (uint256 i = 0; i < _holders.length; i++) {
            newROwned = (_rOwned[_holders[i]]*_rTotalInitial)/_rTotal;
            totalNewROwned += newROwned;
            _rOwned[_holders[i]] = newROwned;
        }
        _rTotal = totalNewROwned;
        _rSupplyNeedsReset = false;
        return true;
    }
}