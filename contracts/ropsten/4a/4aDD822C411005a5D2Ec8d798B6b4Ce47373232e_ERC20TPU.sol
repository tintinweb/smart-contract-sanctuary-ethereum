// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/** 
 * @title A simple ERC20 contract
 * @author Malko A.
 * @dev All function calls are currently implemented without side effects
 */
contract ERC20TPU {
    string _name;
    uint256 _totalSupply;
    string _symbol;
    address _owner;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowance;

    /**
     * @notice This event contains transaction data
     * @dev Called in the _transfer, _mint, _burn function
     * @param from The address where funds are debited from
     * @param to Address where funds are credited
     * @param value The amount of tokens that are involved in the transaction
     */
    event Transfer(
        address from,
        address to,
        uint256 value
    );

    /**
     * @notice This event contains transaction data
     * @dev Called in the _approve function
     * @param owner Address of the owner of the tokens
     * @param spender The address of the user that the owner of the tokens allowed to spend them
     * @param value The amount of tokens that are involved in the transaction
     */
    event Approval(
        address owner,
        address spender,
        uint256 value
    );

    constructor(string memory names, string memory symbols, address owner) {
        _name = names;
        _symbol = symbols;
        _owner = owner;
    }

    /**
     * @notice The function returns the name of the token
     */
    function name() external view returns(string memory) {
        return _name;
    }

    /**
     * @notice The function returns the symbol of the token
     */
    function symbol() external view returns(string memory) {
        return _symbol;
    }

    /**
     * @notice The function returns the total supply of tokens
     */
    function totalSupply() external view returns(uint256) {
        return _totalSupply;
    }

    /**
     * @notice The function returns the decimal places of the token
     */
    function decimals() external pure returns(uint8) {
        return 18;
    }

    /**
     * @notice The function returns the user's balance
     * @param account User address
     */
    function balanceOf(address account) external view returns(uint256) {
        return _balances[account];
    }

    /**
     * @notice Function to transfer funds from msg.sender to recipient
     * @param recipient Address where funds are credited
     * @param amount The amount of tokens that are involved in the transaction
     */
    function transfer(address recipient, uint256 amount) external returns(bool) {
        _transfer(msg.sender, recipient, amount);

        return true;
    }

    /**
     * @notice Returns the balance of funds available to the spender
     * @param owner Address of the owner of the tokens
     * @param spender The address of the user that the owner of the tokens allowed to spend them
     */
    function allowance(address owner, address spender) external view returns(uint256) {
        return _allowance[owner][spender];
    }

    /**
     * @notice Function that gives spender access to spend money msg.sender
     * @param amount The amount of tokens that are involved in the transaction
     * @param spender The address of the user that the owner of the tokens allowed to spend them
     */
    function approve(address spender, uint256 amount) external returns(bool) {
        _approve(msg.sender, spender, amount);

        return true;
    }

    /**
     * @notice A function that transfers funds from the sender to the recipient 
     * and reduces the balance of funds that the recipient can spend     
     * @param amount The amount of tokens that are involved in the transaction
     * @param sender The address of the user who allowed to spend their funds
     * @param recipient The address of the user that the owner of the tokens allowed to spend them
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns(bool) {
        _transfer(sender, recipient, amount);

        uint256 balance =_allowance[sender][recipient];
        require(balance >= amount, "Invalid amount");
        
        _approve(sender, recipient, balance - amount);

        return true;
    }

    /**
     * @notice A function that increases the balance of funds that msg.sender has allowed the spender to spend
     * @param addedValue Funding amount to be added to _allowance
     * @param spender The address of the user who allowed to spend their funds
     */
    function increaseAllowance(address spender, uint256 addedValue) external  returns(bool) {
        uint256 balance = _allowance[msg.sender][spender];

        _approve(msg.sender, spender, addedValue + balance);
        
        return true;
    }

    /**
     * @notice A function that reduces the balance of funds that msg.sender has allowed the sender to spend
     * @param subtractedValue Amount of funding to be withdrawn from _ allowance
     * @param spender The address of the user who allowed to spend their funds
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) external  returns(bool) {
        uint256 balance = _allowance[msg.sender][spender];
        require(balance >= subtractedValue, "Invalid amount");

        _approve(msg.sender, spender, balance - subtractedValue);

        return true;
    }

    /**
     * @notice A function that creates tokens and replenishes the account balance
     * @param amount Number of tokens to create
     * @param account User address for which tokens are created
     */
    function mint(address account, uint256 amount) external returns(bool) {
        require(msg.sender == _owner, "Invalid address");

        _mint(account, amount);

        return true;
    }

    /**
     * @notice A function that burns the tokens of the user who called it
     * @param amount Amount of tokens to be burned
     */
    function burn(uint256 amount) external  returns(bool) {
        _burn(msg.sender, amount);

        return true;
    }

    /**
     * @notice A function that burns the amount of tokens that the account has allowed 
     * the person who calls the function to spend
     * @param amount Amount of tokens to be burned
     * @param account The address of the user who allowed to spend their funds
     */
    function burnFrom(address account, uint256 amount)  external returns(bool) {
        _burnFrom(account, amount);

        return true;
    }

    /**
     * @notice Function to transfer funds from msg.sender to recipient
     * @param recipient Address where funds are credited
     * @param sender The address where funds are debited from
     * @param amount The amount of tokens that are involved in the transaction
     */
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "Sender invalid address");
        require(recipient != address(0), "Recipient invalid address");
        require(_balances[sender] >= amount, "Invalid amount");

        _balances[sender] -= amount;
        _balances[recipient] += amount;

        emit Transfer(
            sender,
            recipient,
            amount
        );
    }

    /**
     * @notice A function that creates tokens and replenishes the account balance
     * @param amount Number of tokens to create
     * @param account User address for which tokens are created
     */
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "Account address invalid");

        _balances[account] += amount;
        _totalSupply += amount;

        emit Transfer(
            address(0), 
            account, 
            amount
        );
    }

    /**
     * @notice A function that burns the amount of tokens that the account has allowed 
     * the person who calls the function to spend
     * @param amount Amount of tokens to be burned
     * @param account The address of the user who allowed to spend their funds
     */
     function _burnFrom(address account, uint256 amount) internal {
        uint256 balance = _allowance[account][msg.sender];

        _burn(account, amount);
        _approve(account, msg.sender, balance - amount);
    }

    /**
     * @notice A function that burns the tokens of the user who called it
     * @param amount Amount of tokens to be burned
     * @param account The address of the user who decided to call the burn function
     */
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "Account addres invalid");
        require(_balances[account] >= amount, "Invalid amount");

        _balances[account] -= amount;
        _totalSupply -= amount;

        emit Transfer(
            account,
            address(0),
            amount
        );
    }

    /**
     * @notice Function that gives spender access to spend money msg.sender
     * @param amount The amount of tokens that are involved in the transaction
     * @param spender The address of the user that the owner of the tokens allowed to spend them
     * @param owner Address of the user who allows the spender to spend his tokens
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "Owner address invalid");
        require(spender != address(0), "Spender address invalid");

        _allowance[owner][spender] = amount;

        emit Approval(
            owner,
            spender,
            amount
        );
    }

}