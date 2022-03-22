/**
 *Submitted for verification at Etherscan.io on 2022-03-22
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;



// Part: IERC20

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

// File: Aguia.sol

/*
* @title: 
*        $AGU, an ERC-20 standard token.
* @author: Anthony ($AGU).
* @date: 21/03/2022.
*
* @notice: This token, $AGU, obeys the standard of the ERC-20, created as my debut token.
* Also, currently, I do not seem to understand the concept of the allowance, approve and transferFrom functions but 
* I hope Reddit comes to my aid.
*
* I M P O R T A N T :
* '{text}' => Implies text is a data type.
* `{text}` => Implies text is a variable name.
*
* T L D R :
* 'data_type'
* `variable_name`
*/

contract AGU is IERC20
{
    /*
    * @dev: Sets and allocates some tokens as `balances` to `addresses`.
    * Also creates an allowance between the 'address' {`_owner`} and 'address' {`spender`} to a particular 'uint' `allowance`
    */

    mapping (address => uint) private balances;
    
    mapping (address => mapping (address => uint)) private _allowance;

    /*
    * @dev: Setting a 1 million total supply of the $AGU token and the decimal.
    */
    uint256 private _totalSupply;
    uint8 private _decimal;
    
    /*
    * @dev: Setting token name and symbol.
    */
    string private _name;
    string private _symbol;
    address constant _owner = 0x5e078E6b545cF88aBD5BB58d27488eF8BE0D2593;
    
    /*
    * @dev: Constructor
    */
    constructor()
    {
        _name = "Aguia";
        _symbol = "$AGU";

        // total supply is 1 million plus the 3 decimal zeros
        _totalSupply = 1000000000;
        _decimal = 3;

        // address _owner = msg.sender;

        // get the _owner of the contract and assign to him all the funds
        // balances[msg.sender] = _totalSupply;

        // allocate all to me
        balances[_owner] = _totalSupply;
    }

    /*
    * @dev: `name()` function returns the name of the token
    */
    function name() public view returns(string memory)
    {
        return _name;
    }

    
    /*
    * @dev: `symbol()` function returns the token symbol
    */
    function symbol() public view returns(string memory)
    {
        return _symbol;
    }

    
    /*
    * @dev: `decimals()` function returns the token decimals
    */
    function decimals() public view returns(uint8)
    {
        return _decimal;
    }

    /*
    * @notice: Implementation of functions necessary according to the ERC-20 standard.
    * Function 1:
    *
    *
    * @dev: `totalSupply()` function returns the total number of token coins in existence
    */
    function totalSupply() public view virtual override returns(uint)
    {
        return _totalSupply;
    }

    /*
    * @notice: Function 2:
    *
    * @dev: `balanceOf()` function: Returns the amount of token owned by a particular `account`
    */
    function balanceOf(address account) public view virtual override returns (uint)
    {
        return balances[account];
    }

    /*
    * @notice: Function 3:
    *
    * @dev: `transfer()` function: Transfers some token `amount` to a particular account of 'address', `to`, from the callers account
    * -- increments the `balances` of `to` by `amount`
    * -- decrements the `balances` of `msg.sender` by `amount`
    *
    * Returns a boolean that shows that it worked
    *
    * Emits a {Transfer} event
    *
    *
    * @notice: This function is controlled by a modifier `canSend()` that makes sure that the sender has enough token in his account to send
    */
    modifier canSend(address from, address to, uint amount)
    {
        require(from != address(0), "You cannot transfer from an invalid address.");

        require(to != address(0), "You cannot transfer to an invalid address.");

        require(amount != 0, "You cannot send 0 $AGU.");

        require(balances[from] >= amount, "You do not have enough $AGU Coins to make this transaction.");
        _;
    }

    function transfer(address to, uint amount) public virtual override canSend(msg.sender, to, amount) returns(bool)
    {
        balances[to] += amount;
        balances[msg.sender] -= amount;
        emit Transfer(msg.sender, to, amount);

        return true;
    }

    /*
    * @notice: Function 4:
    * @dev: `approve()` Sets `amount` as the allowance of `spender` over the caller's tokens. 
    *  Emits an {Approval} event.
    *
    * This is protected by a modifier
    */
    modifier canApprove(address spender, uint amount)
    {
        require(spender != address(0), "You cannot request from an invalid address.");
        require(amount > 0, "You can't request for empty allowance.");
        require(balances[_owner] > amount, "Cannot approve alowance.");
        require(_allowance[_owner][spender] + amount < 100, "Allowance limit reached");
        require(amount <= 100, "Allowance limit is 100.");
        _;
    }

    function approve(address spender, uint amount) public virtual canApprove(spender, amount) override returns(bool)
    {
        _allowance[_owner][spender] += amount;
        emit Approval(_owner, spender, amount);
        return true;
    }

    /*
    * @notice: Function 5:
    * @dev: `transferFrom()` Moves `amount` tokens from `from` to `to` using the
    * allowance mechanism. `amount` is then deducted from the caller's
    * allowance.
    *
    * Returns a boolean value indicating whether the operation succeeded.
    *
    * Emits a {Transfer} event.
    *
    * This is controlled by a modifier.
    */
    modifier canTransfer(address from, address to, uint amount)
    {
        require(_allowance[_owner][from] > amount, "You do not have enough allowance");
        require(to != address(0), "You cannot transfer to an invalid address.");
        require(amount != 0, "You cannot send 0 $AGU.");
        _;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override canTransfer(msg.sender, to, amount) returns(bool)
    {
        from = msg.sender;
        balances[to] += amount;
        _allowance[_owner][from] -= amount;
        emit Transfer(from, to, amount);
        return true;
    }


    /*
    * @notice: Function 6:
    * @dev: `allowance()` Returns the remaining number of tokens that `spender` will be
    * allowed to spend on behalf of `_owner` through {transferFrom}. This is
    * zero by default.
    *
    * This value changes when {approve} or {transferFrom} are called.
    */
    
    function allowance(address owner, address spender) public view virtual override returns (uint256)
    {
        owner = _owner;
        return (_allowance[owner][spender]);
    }
    
    /*
    * @notice: MINT
    * this function mints more tokens
    */
    modifier onlyOwner()
    {
        require(msg.sender == _owner, "You cannot mint more of this token.");
        _;
    }

    function mint(uint amount) public onlyOwner returns(bool)
    {
        _totalSupply += amount;
        balances[_owner] += amount;
        return true;
    }

    function burn(uint amount) public onlyOwner returns(bool)
    {
        _totalSupply -= amount;
        balances[_owner] -= amount;
        return true;
    }
}