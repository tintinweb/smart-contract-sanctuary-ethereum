/**
 *Submitted for verification at Etherscan.io on 2022-03-09
*/

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




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

// File: erc-20-child.sol


pragma solidity ^0.8.10;



/*
* @dev contract to create ownable ERC-20 token 
* 
* takes name, symbol and the amount of token to be minted
*
* Minters and pauser for the token can be added by the owner 
* 
* tokens can also be burnt 
*/

contract Token is ERC20 , Ownable{

    bool _paused;
    mapping(address => uint256) private _balances;
    mapping(address=>bool) minters;
    mapping(address=>bool) pausers;
    
    event MinterAdded(address);
    event MinterRemoved(address);
    event PauserAdded(address);
    event PauserRemoved(address);

    /*
    * @dev sets the name , symbol and amount of the token 
    * 
    * mints the amount of token supplied 
    * 
    * Makes the deployer transaction sender the owner of the contract 
    */
    constructor(string memory name, string memory symbol, uint amount) ERC20(name, symbol) Ownable(){
        _mint(msg.sender, amount*10**(decimals()) );
    }

    /*
    * @dev checks if msg sender is minter
    */
    modifier onlyMiner(){
        require(minters[msg.sender] == true, "Not authorized to mine");
        _;
    }

    /*
    * @dev checks if msg sender is a pauser
    */
    modifier onlyPauser(){
        require(pausers[msg.sender] == true, "not authorized to puase");
        _;
    }

    /*
    * @dev checks if the contract is paused 
    */
    modifier whenPaused(){
        require(_paused == true, " Contract is not paused ");
        _;
    }

    /*
    * @dev checks if the contract is not paused 
    */
    modifier whenNotPaused(){
        require(_paused == false, "contract is not paused ");
        _;
    }

    /*
    * @dev returns bool for is the account a minter
    * 
    * checks if the account in not zero address 
    *
    * Then returns is the account is a minter
    */
    function isMinter(address account) public returns(bool) {
        require(account != address(0));
        return minters[account];
    }

    /*
    * @dev adds minter to the minters mapping 
    * 
    * checks if the sender is the owner 
    * 
    * adds minter to the minters mapping 
    *
    * emits MinterAdded event 
    */
    function addMinter(address account) public onlyOwner() {
        require(account != address(0), " addMinter: Zero address provided for account. Not a valid address ");
        _addMinter(account);
        emit MinterAdded(account);
    }

    /*
    * @dev adds minter to the minters mapping 
    * 
    * checks if the contact is paused
    *
    * then adds the minter 
    */
    function _addMinter(address account) internal whenNotPaused(){
        minters[account] = true;
    }

    /*
    * @dev removes minter form the minters mapping
    * 
    * takes account adderess
    *
    * checks if the sender is the owner
    * 
    * checks if the account is  not a zero address
    * 
    * removes minter form the minters mapping
    * 
    * emits MinterRemoved log with account 
    *
    */
    function renounceMinter(address account) public onlyOwner(){
        require(account != address(0), " renounceMinter: Zero address provided for account. Not a valid address ");
        require(minters[account] = true, "renounceMinter : account provieded is not an authorized minter");
        _removeMinter(account);
        emit MinterRemoved(account);
    }

    /*
    * @dev removes minter from the minters mapping 
    *
    */
    function _removeMinter(address account) internal whenNotPaused(){
        minters[account] = false; 
    }

    /*
    * @dev mints the tokens and add them to the account address
    */ 
    function mint(address account, uint256 amount) public onlyMiner() whenNotPaused(){
        _mint(account, amount);
    }

    /*
    *@dev burns the token amount 
    * 
    */
    function burn(uint amount) public whenNotPaused(){
        _burn(msg.sender, amount);
    }

    /*
    * @dev burns the token from the account provided 
    * 
    * Checks the allowance of the msg sender 
    * 
    * Then burns the token from the account provided
    */
    function burnFrom(address account, uint amount) public whenNotPaused(){
        _spendAllowance(account, msg.sender, amount);
        _burn(account, amount);
    }

    /*
    * @dev returns true if the account is a pauser
    * 
    */
    function isPauser(address account) public returns(bool){
        require(account != address(0));
        return pausers[account];
    }

    /*
    * @dev adds pauser account 
    * 
    * checks if the sender is owner
    * 
    * checks if the account is not zero address 
    * 
    * adds pauser account
    * 
    * emits the PauserAdded log 
    */
    function addPauser(address account) public onlyOwner(){
        require(account != address(0), "addPauser: Zero address provided for account. Not a valid address");
        _addPauser(account);
        emit PauserAdded(account);
    }

    /*
    *
    * @dev adds pauser to the pausers mapping 
    * 
    * checks for is the contract is not paused 
    * 
    * then adds pauser to the pausers mapping
    */
    function _addPauser(address account) internal whenNotPaused(){
        pausers[account] = true;
    }

    /*
    * @dev removes pauser for the pauser mapping 
    * 
    * checks the sender is the owner
    * 
    * checks if the account is not zero 
    * 
    * checks if the account is a pauser 
    * 
    * removes pauser for the pauser mapping
    * 
    * emits a PauserRemoved log 
    * 
    */ 
    function renouncePauser(address account) public onlyOwner(){
        require(account != address(0), "renouncePauser : Zero address provided for account. Not a valid address");
        require(pausers[account] = true, "renouncePauser : Account provided is not an authorized pauser");
        _removePausers(account);
        emit PauserRemoved(account);
    }

    /*
    * 
    * @dev removes pauser from the pauser mappping 
    *  
    * checks if the contract is not paused 
    * 
    * removes pauser from the pauser mappping
    * 
    */
    function _removePausers(address account) internal whenNotPaused(){
        pausers[account] = false;
    }

    /*
    * @dev returns if the contract is paused 
    * 
    */
    function  paused() public returns(bool){
        return _paused; 
    }

    /*
    *@dev sets the account to be paused or not 
    *
    */
    function setPaused(bool value) public onlyPauser(){
        _paused = value;
    }

    /*
    * @dev transfers "amount" of  token from "from" address to "to" address 
    */
    function _transfer(
        address from,
        address to,
        uint256 amount 
    ) internal override whenNotPaused() {
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

    /*
    * @dev fall back function to except payment
    */
    fallback() external payable {
    }
}

// File: erc-20-factory.sol


pragma solidity ^0.8.10;
/*
* @dev Implemntation of ERC-20 factory contract for token creation
*
* Token  creation is a payable proccess with a rate per token which 
* could be set 
*
* There are two fees for token creation ie referal fee and manager fee
* deducted from the ether sent for token creation.
* 
* Rest of the ether supplied would be transfered to the token contract 
* created 
*
*/ 

 contract ERC20factory {  

    uint256 feeMannagerRate;
    uint256 referalManagerRate;
    uint256 ratePerToken;
    bool internal locked;
    uint256 counter;
    address owner;
    uint256 public lastWithdrawalTime;
    mapping(address=>bool)childern;

    event log(address);
    event WithDraw(uint);
    event amounts(uint);

    /*
    * @dev set value of token rate  , referal rate , mannager rate
    * 
    * The value of owner will be set as message sender of contract 
    * deployment transaction
    * 
    * The last with drawl time would be initialize to the block time
    * of the contract deployment transaction.
    * 
    */ 
    constructor(uint tokenRate,uint referalRate, uint mannagerRate){
        feeMannagerRate = mannagerRate;
        referalManagerRate = referalRate;
        ratePerToken = tokenRate;
        lastWithdrawalTime = block.timestamp;
        owner = msg.sender;
    }

    /*
    * @dev modifier to attach to prevent re-entrancy attack 
    * using the locked variable 
    */ 
    modifier noReentrancy(){
        require(!locked, "noReentrancy: Cant run the function again ");
        locked = true;
        _;
        locked = false;
    }

    /*
     *  @dev  returns the created token contarct address
     *  
     *  Takes the name , synbol and the amount of the token to be created
     * 
     *  Checks for the value of ether sent to be greater than the required
     *  rate of token 
     *  
     *  Saves the token contract address in the childer mappping 
     *
     *  Creates the Token contract and takes the  referal and mannager fee 
     *  
     *  Sends the remaining amount to the token contract address
     *   
     *  Emits token contract address 
     *  
     *  Returns the tokenc contract address  
     */
    function createToken(string memory name, string memory symbol, uint amount) external payable noReentrancy() returns(address){
        require(msg.value >= ratePerToken*amount, "createToken: Ether value sent is less than the amount required to mint token. Please send sufficent ether");
        Token token = new Token(name, symbol, amount);
        address addressToken = address(token);
        _addContractAddress(addressToken);
        uint256  balance = address(this).balance;
        uint256  expences = amount*ratePerToken*(feeMannagerRate + referalManagerRate)/100;
        uint256  amountToSend = msg.value - expences;
        (bool sent,) = addressToken.call{value: amountToSend}(" ");
        require(sent, "createToken: failed to send ether to child contract");
        require(address(this).balance == (balance - amountToSend));
        emit log(addressToken);
        return addressToken;
    }

    /*
    * @dev Adds the token contract address to the childer mapping 
    * 
    * Increases the counter by one for each contract added 
    */
    function _addContractAddress(address account) internal {
         childern[account] = true;
         counter++;
    }

    /*
    * @dev returns the counter of the token contract created 
    */
    function getCounter() external returns (uint256){
        return counter;
    }

    /* 
    * @dev returns the token creation rate 
    */
    function getTokenRate() external returns(uint256){
        return ratePerToken == 0 ? 0 : ratePerToken;
    }

    /*
    * @dev returns the mannager fee rate in percent 
    */
    function getFeeManagerRate() external returns(uint256){
        return feeMannagerRate == 0 ? 0 : feeMannagerRate;
    }

    /*
    * @dev returns the refereal manager fee rate in percentage 
    */
    function getReferalManagerRate() external returns(uint256){
        return referalManagerRate == 0 ? 0 : referalManagerRate;
    }

    /* 
    *@dev sets the fee manager rate in percent 
    */
    function setFeeManager(uint256 value) external {
        feeMannagerRate = value;
    }

    /*
    * @dev sets the refereal mannager rate in percent
    */
    function setReferalManager(uint256 value) external {
        referalManagerRate = value;
    }

    /*
    * @dev returns the balance of the contract address 
    */
    function checkBalance() external returns(uint){
        return address(this).balance;
    }

    /*
    * @dev withdraw amount from the contract to the owner 
    * 
    * checks for the withdrawal time be 15 days more than
    * last withrawal time  
    */
    function withdrawal(uint amount) external {
        require(block.timestamp >= lastWithdrawalTime + 15 days, "withdrawal: 15 days have not passed from last withdrawal please wait");
        (bool sent,) = owner.call{value: amount}(" ");
        require(sent, "withdrawal: Cant with draw ether from the contact ");
        lastWithdrawalTime = block.timestamp;
        emit WithDraw(amount);
    }

    /*
    * @dev returns the last withdrawal time 
    */
    function getlastWithdrawalTime() external returns(uint256){
        return lastWithdrawalTime;
    }

 }