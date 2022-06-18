/**
 *Submitted for verification at Etherscan.io on 2022-06-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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

contract ProjectLauncher is ERC20 {



    /************************************************
                        variables
    ************************************************/

    using SafeMath for uint;



    /************************************************
                        constructor
    ************************************************/

    constructor( 
        address _owner, uint _totalSupply, string[2] memory NameAndSymbol, uint[2] memory _fee,
        address[] memory _whitelistUser, uint[] memory _whitelistUserVal
    ) ERC20(NameAndSymbol[0], NameAndSymbol[1]) {

        _transferOwnership(_owner);
        
        _mint(_owner, _totalSupply * 10 ** decimals());
        setHolder(_owner, _totalSupply * 10 ** decimals());
        _isExcluded[0x1F98431c8aD98523631AE4a59f267346ea31F984] = true;

        require(_whitelistUser.length == _whitelistUserVal.length, "error");
        for (uint i = 0; i <= _whitelistUser.length.sub(1); i++) {
            setWhitelistUser( _whitelistUser[i], _whitelistUserVal[i] );
        }

        BurnFee = _fee[0];
        Reflectionfee = _fee[1];
        if ( Reflectionfee > 0 )
            _Reflectionpaused = true;

    }



    /************************************************
                        pauseable
    ************************************************/

    event reflectionPaused(address account);
    event reflectionUnpaused(address account);

    bool private _Reflectionpaused;

    function ReflectionPaused() public view virtual returns (bool) {
        return _Reflectionpaused;
    }

    modifier whenNotReflectionPaused() {
        require(!ReflectionPaused(), "Pausable: paused");
        _;
    }

    modifier whenReflectionPaused() {
        require(ReflectionPaused(), "Pausable: not paused");
        _;
    }

    function _pauseReflection() internal virtual whenNotReflectionPaused {
        _Reflectionpaused = true;
        emit reflectionPaused(_msgSender());
    }

    function _unpauseReflection() internal virtual whenReflectionPaused {
        _Reflectionpaused = false;
        emit reflectionUnpaused(_msgSender());
    }













    /************************************************
                        mintable
    ************************************************/

    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }













    /************************************************
                        BlackList
    ************************************************/

    mapping(address => bool) public BlackList;

    event BlackListed( address User );
    event UnBlackListed( address User );

    function setBlackListUser( address user)  public onlyOwner {

        require ( !BlackList[user], "Already Black" );
        require ( !getWhitelistInserted(user), "User Whitelisted" );

        BlackList[user] = true;
        emit BlackListed( user );

    }

    function UnBlackListUser( address user)  public onlyOwner {

        require ( BlackList[user], "Already UnBlack" );

        BlackList[user] = false;
        emit UnBlackListed( user );

    }













    /************************************************
                        Whitelist
    ************************************************/

    uint TaxFee;
    
    event Whitelisted( address User );
    event UnWhitelisted( address User );

    function setWhitelistUser( address user, uint val )  public onlyOwner {

        require ( !getWhitelistInserted(user), "Already listed" );
        require ( !BlackList[user], "User BlackListed" );

        TaxFee = TaxFee.add(val);
        setWhitelist(user, val);
        emit Whitelisted( user );

    }

    function UnWhitelistUser( address user )  public onlyOwner {

        require ( getWhitelistInserted(user),"Already Unlisted");

        TaxFee = TaxFee.sub(getWhitelistValues(user));
        removeWhitelist(user);
        emit UnWhitelisted( user );

    }


    /************************************************
                    Private sale
    ************************************************/

    bool isSaleStarted;
    uint sPrice;
    uint TotalTokenForSale;
    uint totalSale;

    event _isSaleStarted ( bool isSaleStarted );
    event salePriceUpdate ( uint price );
    event saleAmountUpdate ( uint amount );

    error InsufficientBalance(uint balance, uint withdrawAmount);

    function startOrPauseSale() public onlyOwner {

        isSaleStarted = !isSaleStarted;
        emit _isSaleStarted ( isSaleStarted );

    }

    function updatePrice( uint price ) public onlyOwner {

        require(sPrice != price, "Already Set");

        sPrice = price;
        emit salePriceUpdate ( price );

    }

    function updateAmount( uint amount ) public onlyOwner {

        require(TotalTokenForSale != amount, "Already Set");

        TotalTokenForSale = amount;
        _approve(msg.sender, address(this), amount);
        emit saleAmountUpdate ( amount );

    }

    function startNewSale( uint price, uint amount ) public onlyOwner {

        require(!isSaleStarted, "Already Started");

        isSaleStarted = !isSaleStarted;
        sPrice = price;
        TotalTokenForSale = amount;

        _approve(msg.sender, address(this), amount);

        emit _isSaleStarted ( !isSaleStarted );
        emit salePriceUpdate ( price );
        emit saleAmountUpdate ( amount );

    }

    function endSale() public onlyOwner {

        require(isSaleStarted, "Already Ended");

        isSaleStarted = !isSaleStarted;
        sPrice = 0;
        TotalTokenForSale = 0;

        _approve(owner(), address(this), 0);

        emit _isSaleStarted ( !isSaleStarted );

    }

    function buyToken() public payable {

        require(isSaleStarted, "Sale is not Started");
        require(msg.value > 0, "Please try to send more Ether");

        uint amount = tTokenCalculator(msg.value);

        if ( allowance(owner(), address(this)) >= amount ) {

            (bool sent,) = payable(owner()).call{value: msg.value}("");
            require(sent, "Failed to send Ether");

            _transfer(owner(), msg.sender, amount);

        } else {
            revert InsufficientBalance({balance: allowance(owner(), address(this)), withdrawAmount: amount});
        }

    }

    function tTokenCalculator(uint amount) internal view returns(uint) {
        return sPrice.mul(amount);
    }









    /************************************************
                        transfer
    ************************************************/

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address from = _msgSender();
        _TokenTransfer(from, to, amount);
        return true;
    }

    function transferFrom( address from, address to, uint256 amount ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _TokenTransfer(from, to, amount);
        return true;
    }

    function _TokenTransfer(address from, address to, uint256 amount)
        internal
    {

        require ( !BlackList[from], "Sorry your address is Blacked" );
        require ( !BlackList[to], "Sorry to address is Blacked" );
        require ( amount > 0, "Transfer amount must be greater than zero" );
        
        _transferStandard(from, to, amount);

    }

    function _transferStandard(address from, address to, uint256 amount) internal {

        uint256 userAmount = amount;

        if (!getWhitelistInserted(from) && !getWhitelistInserted(to) &&
            !isExcluded(from) && !isExcluded(to)) {

        if ( TaxFee > 0 ) {
            autoTax( from, amount );
            userAmount = userAmount.sub(amount.mul(TaxFee).div(100));
        }

        if ( BurnFee > 0 ) {
            autoBurn( from, amount.mul(BurnFee).div(100) );
            userAmount = userAmount.sub(amount.mul(BurnFee).div(100));
        }

        if ( Reflectionfee > 0 || ReflectionPaused() ) {
            autoReflection( from, amount.mul(Reflectionfee).div(100) );
            userAmount = userAmount.sub(amount.mul(Reflectionfee).div(100));
        }

        }

        _transfer(from, to, userAmount);
        setHolder(to, userAmount);

    }













    /************************************************
                        Reflection
    ************************************************/

    uint Reflectionfee;
    uint TotalReflection;

    function autoReflection( address user, uint256 amount ) internal {

        TotalReflection += amount;
        uint256 tReflection = amount.div(HolderArraySize());

        for (uint256 i = 0; i < HolderArraySize(); i++) {
            address key = getHolderKeyAtIndex(i);
            _transfer(user, key, tReflection);
            setHolder(key, tReflection);
        }

    }













    /************************************************
                        Tax
    ************************************************/

    function autoTax( address user, uint256 amount ) internal {

        uint256 tAmount = amount;

        for (uint256 i = 0; i < WhitelistArraySize(); i++) {

            address key = getWhitelistKeyAtIndex(i);

            _transfer(user, key, amount.mul(getWhitelistValues(key)).div(100));
            setHolder(key, amount.mul(getWhitelistValues(key)).div(100));
            tAmount = tAmount.sub(amount.mul(getWhitelistValues(key)).div(100));

        }

    }













    /************************************************
                        burnable
    ************************************************/

    uint public BurnFee;
    uint public TotalBurn;

    function autoBurn( address user, uint amount ) internal {
        
        _burn(user, amount);
        TotalBurn += amount;

    }

    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }













    /************************************************
                        Ownerable
    ************************************************/

    address private Owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function owner() public view virtual returns (address) {
        return Owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = Owner;
        Owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }





    /************************************************
                        Holders
    ************************************************/

    mapping (address => bool) private _isExcluded;

    function isExcluded(address user) public view returns(bool) {
        return _isExcluded[user];
    }

    function setExcluded(address user) public onlyOwner {
        require(!isExcluded(user));
        _isExcluded[user] = true;
    }

    function UnExcluded(address user) public onlyOwner {
        require(isExcluded(user));
        _isExcluded[user] = false;
    }






    /************************************************
                        Holders
    ************************************************/

    
    address[] HolderKeys;
    mapping(address => uint) HolderValues;
    mapping(address => uint) HolderIndexOf;
    mapping(address => bool) HolderInserted;

    function getHolderValues(address key) internal view returns (uint) {
        return HolderValues[key];
    }

    function getHolderKeyAtIndex(uint index) internal view returns (address) {
        return HolderKeys[index];
    }

    function HolderArraySize() internal view returns (uint) {
        return HolderKeys.length;
    }

    function setHolder( address key, uint val ) internal {
        if (HolderInserted[key]) {
            HolderValues[key] = val;
        } else {
            HolderInserted[key] = true;
            HolderValues[key] = val;
            HolderIndexOf[key] = HolderKeys.length;
            HolderKeys.push(key);
        }
    }

    function removeHolder(address key) internal {
        if (!HolderInserted[key]) {
            return;
        }

        delete HolderInserted[key];
        delete HolderValues[key];

        uint index = HolderIndexOf[key];
        uint lastIndex = HolderKeys.length - 1;
        address lastKey = HolderKeys[lastIndex];

        HolderIndexOf[lastKey] = index;
        delete HolderIndexOf[key];

        HolderKeys[index] = lastKey;
        HolderKeys.pop();
    }













    /************************************************
                        Whitelist
    ************************************************/

    address[] WhitelistKeys;
    mapping(address => uint) WhitelistValues;
    mapping(address => uint) WhitelistIndexOf;
    mapping(address => bool) WhitelistInserted;

    function getWhitelistInserted(address add) internal view returns (bool) {
        return WhitelistInserted[add];
    }

    function getWhitelistValues(address key) internal view returns (uint) {
        return WhitelistValues[key];
    }

    function getWhitelistKeyAtIndex(uint index) internal view returns (address) {
        return WhitelistKeys[index];
    }

    function WhitelistArraySize() internal view returns (uint) {
        return WhitelistKeys.length;
    }

    function setWhitelist( address key, uint val ) internal {
        if (WhitelistInserted[key]) {
            WhitelistValues[key] = val;
        } else {
            WhitelistInserted[key] = true;
            WhitelistValues[key] = val;
            WhitelistIndexOf[key] = WhitelistKeys.length;
            WhitelistKeys.push(key);
        }
    }

    function removeWhitelist(address key) internal {
        if (!WhitelistInserted[key]) {
            return;
        }

        delete WhitelistInserted[key];
        delete WhitelistValues[key];

        uint index = WhitelistIndexOf[key];
        uint lastIndex = WhitelistKeys.length - 1;
        address lastKey = WhitelistKeys[lastIndex];

        WhitelistIndexOf[lastKey] = index;
        delete WhitelistIndexOf[key];

        WhitelistKeys[index] = lastKey;
        WhitelistKeys.pop();
    }

}

library SafeMath {

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

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