/**
 *Submitted for verification at Etherscan.io on 2022-05-15
*/

// Sources flattened with hardhat v2.9.5 https://hardhat.org

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


// File contracts/Yapes.sol

pragma solidity ^0.8.0;


contract Yapes is IERC20, Ownable {

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public noTaxWhitelist;
    mapping(address => bool) public minters;
    uint256 fee;
    address benefactor;


    string private _name;
    string private _symbol;
    uint256 private _totalSupply;

    /**
     * @dev Emitted when tokens are moved from one account to
     * another and fee `amount` is taken.
     */
    event Fee( uint256 amount);
    /**
     * @dev Emitted when `account` is whitelisted.
     */
    event Whitelisted( address account);
    /**
     * @dev Emitted when `account` is unwhitelisted.
     */
    event Unwhitelisted( address account);
    /**
     * @dev Emitted when `account` is added as minter.
     */
    event AddMinter( address amount);
    /**
     * @dev Emitted when `account` is removed as minter.
     */
    event RemoveMinter( address amount);
    /**
     * @dev Emitted when `account` is a new benefactor.
     */
    event NewBenefactor( address amount);

    modifier onlyMinter() {
        require(minters[msg.sender] || owner() == msg.sender);
        _;
    }

    constructor(address _benefactor) public {
        _name = "Yapes Token";
        _symbol = "YAPES";
        benefactor = _benefactor;
    }

    function changeBenefactor(address _benefactor) external onlyOwner {
        benefactor = _benefactor;
        emit NewBenefactor(_benefactor);
    }

    /**
     * @dev Adds address to the notTaxWhitelist.
     *
     * @param account - address to add
     */
    function whitelist(address account) external onlyOwner {
        noTaxWhitelist[account] = true;
        emit Whitelisted(account);
    }


    /**
     * @dev Removes address from the notTaxWhitelist.
     *
     * @param account - address to remove
     */
    function removeFromWhitelist(address account) external onlyOwner {
        noTaxWhitelist[account] = false;
        emit Unwhitelisted(account);
    }



    /**
     * @dev Adds address to the minters.
     *
     * @param account - address to add
     */
    function addMinter(address account) external onlyOwner {
        minters[account] = true;
        emit AddMinter(account);
    }


    /**
     * @dev Removes address from the minters.
     *
     * @param account - address to remove
     */
    function removeMinter(address account) external onlyOwner {
        minters[account] = false;
        emit RemoveMinter(account);
    }

    /**
     * @dev See {IERC20-transfer}. 15% fee is taken for the transfer,
     * only exception are whitelisted addresses.
     *
     * @param to - recipient of transfer
     * @param amount - amount to transfer
     */
    function transfer(address to, uint256 amount) external override returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}. 15% fee is taken for the transfer,
     * only exception are whitelisted addresses.
     *
     * @param from - sender of transfer
     * @param to - recipient of transfer
     * @param amount - amount to transfer
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external override returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * @param spender - address which will be spending tokens
     * @param addedValue - increase in value which will be allowed to spend
     */
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * @param spender - address which will be spending tokens
     * @param subtractedValue - decrease of value which will be allowed to spend
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        address owner = msg.sender;
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
    unchecked {
        _approve(owner, spender, currentAllowance - subtractedValue);
    }

        return true;
    }

    /**
     * @dev Mints `amount` of tokens  to `recipient`.
     *
     * @param account - recipient of mint
     * @param amount - amount to transfer
     */
    function mint(address account, uint256 amount) external onlyMinter {
        _mint(account, amount);
    }

    /**
     * @dev Burns `amount` of tokens from ``recipient`.
     *
     * @param account - recipient of burn
     * @param amount - amount to transfer
     */
    function burn(address account, uint256 amount) external onlyMinter {
        _burn(account, amount);
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * @param spender - address that will be allowed to spend tokens
     * @param amount - amount of allowed tokens to spend
     */
    function approve(address spender, uint256 amount) external override returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, amount);
        return true;
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *  @param account - account to which token is minted
     *  @param amount - amount of minted token
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *  @param account - account from which token is burned
     *  @param amount - amount of burned token
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
    unchecked {
        _balances[account] = accountBalance - amount;
    }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }


    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * @param from - sender of transfer
     * @param to - recipient of transfer
     * @param amount - amount to transfer
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {

        uint256 tax = 0;
        if(!noTaxWhitelist[from]){
            tax = amount * 15 / 100;
        }

        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        require(fromBalance >= amount + tax, "ERC20: unable to pay fee from transfer");
    unchecked {
        _balances[from] = fromBalance - (amount + tax);
    }
        _balances[to] += amount;
        _balances[benefactor] += tax/3;
        _totalSupply -= tax - tax/3;

        emit Transfer(from, to, amount);
        emit Fee(fee);

    }

    /**
 * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * @param owner - address which tokens will be spent
     * @param spender - address which will be spending tokens
     * @param amount - amount of tokens to be spent
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * @param owner - owner of the tokens
     * @param spender - spender of the tokens
     * @param amount - amount of the tokens to send
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        uint256 currentAllowance = _allowances[owner][spender];
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
        unchecked {
            _approve(owner, spender, currentAllowance - amount);
        }
        }
    }

    /**
 * @dev Returns the name of the token.
     */
    function name() external view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     */
    function decimals() external view returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

}