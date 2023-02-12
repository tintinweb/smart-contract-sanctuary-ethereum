// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

/** 
@dev This is a basic ERC-20 token contract written in Solidity programming language. 
It has functions to mint new tokens, burn existing tokens, transfer tokens between accounts, 
and get information about the token such as the name, symbol, maximum supply, decimals, and owner. 
It uses a mapping to store the balances of each account 
and emits a Transfer event whenever a transfer of tokens occurs. 
The contract has a modifier "onlyOwner" which restricts the access of certain functions to the contract owner.
*/

contract BasicERC20 {
    /**
     * @dev This code declares five variables: 
    1. _maxSupply: This variable stores the maximum supply of a cryptocurrency or token. 
    2. _totalSupply: This variable stores the total supply of a cryptocurrency or token. 
    3. _decimals: Stores the number of decimal places used to represent the cryptocurrency. 
    4. _owner: Identifies the owner of the cryptocurrency or token. 
    5. _name and _symbol: Store the name and symbol associated with the cryptocurrency.
    */
    uint256 _maxSupply;
    uint256 _totalSupply;
    uint8 _decimals;
    address _owner;
    string _name;
    string _symbol;

    mapping(address => uint256) private balances;
    event Transfer(address _from, address _to, uint _amount);

    /**
     * This code is a constructor for a smart contract.
     * It sets the _owner variable to the sender of the message,
     * @param name_  sets the _name variable to name_,
     * @param symbol_ sets the _symbol variable to symbol_,
     * @param maxSupply_ sets the _maxSupply variable to maxSupply_
     * multiplied by 10 raised to the power of 18.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 maxSupply_
    ) {
        _owner = msg.sender;
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
        _maxSupply = maxSupply_ * 10 ** _decimals;
    }

    /**
     * @dev This code is a modifier that checks if the sender of the message is the owner.
     * If it is not, then an error message "Not the owner" will be thrown.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Not the owner");
        _;
    }

    /**
     * @dev This code defines a function called "name" that is public, view, and virtual.
     * It returns a string memory value stored in the variable "_name".
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev This code defines a function called "symbol" that is public, viewable, and virtual.
     * It returns a string memory value that is stored in the "_symbol" variable.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev This function allows users to view the maximum supply of a token or asset.
     */
    function maxSupply() public view virtual returns (uint256) {
        return _maxSupply;
    }

    /**
     * @dev This function can be used to access the value of _decimals from outside the code.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev This function is used to retrieve the address of the owner of the contract.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev This code is a function that returns the total supply of a cryptocurrency.
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev This code is a function that mints a certain amount of tokens to a given account.
     * It requires that the account is not address zero,
     * that the amount being minted is greater than zero,
     * and that the max token supply has not been exceeded.
     */
    function _mint(address account_, uint256 amount_) internal returns (bool) {
        require(
            account_ != address(0),
            "Not allowed to mint from address zero"
        );
        require(amount_ > 0, "Amount being minted should be greater than zero");
        require(
            _maxSupply >= _totalSupply + amount_,
            "Max token to minted exceeded"
        );
        uint256 amount = amount_ * 10 ** _decimals;
        _totalSupply += amount;
        balances[account_] += amount;
        emit Transfer(address(0), account_, amount);
        return true;
    }

    /**
     * @dev This function allows the owner of a contract to mint a certain amount of tokens.
     * @param amount_ representing the amount of tokens to be minted,
     * and returns a boolean value indicating whether or not the minting was successful.
     */
    function mint(uint256 amount_) public virtual onlyOwner returns (bool) {
        return _mint(msg.sender, amount_);
    }

    /**
     * This code is a function that returns the balance of a given account.
     * @param account returns the corresponding balance from the balances array.
     */
    function balanceOf(address account) public view virtual returns (uint256) {
        return balances[account];
    }

    /**
     * @dev This code is a function that burns a certain amount of tokens from a given account address.
     * It requires that the account address is not equal to zero,
     * the amount being burned is greater than zero, and the account has enough tokens to burn.
     */
    function _burn(address account_, uint256 amount_) internal returns (bool) {
        require(
            account_ != address(0),
            "Not allowed to burn from address zero"
        );
        require(amount_ > 0, "Amount being burned should be greater than zero");
        require(
            balances[account_] >= amount_,
            "Not enough amount to burn within the account."
        );
        uint256 amount = amount_ * 10 ** _decimals;
        _totalSupply -= amount;
        balances[account_] -= amount;
        emit Transfer(account_, address(0), amount);
        return true;
    }

    /**
     * This code defines a function called "burn" that takes in a parameter called "amount_".
     */
    function burn(uint256 amount_) public virtual onlyOwner returns (bool) {
        return _burn(msg.sender, amount_);
    }

    /**
     * @dev This code is a function that transfers tokens from one address to another.
     * It requires that the address of the sender is not 0,
     * the address of the receiver is not 0,
     * and that the sender and receiver addresses are different.
     * It also requires that there are enough tokens in the sender's account to make the transfer.
     */
    function _transfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal returns (bool) {
        require(_from != address(0), "Cannot transfer token from address 0");
        require(_to != address(0), "Cannot transfer to address 0");
        require(
            _from != _to,
            "_from address must not be the same with _to address"
        );
        require(balances[_from] >= _amount, "Not enough amount to transfer.");
        uint256 amount = _amount * 10 ** _decimals;
        require(
            balances[_from] >= amount,
            "Not enough token to transfer withing the account"
        );
        require(
            _amount > 0,
            "Amount being transferred should be greater than zero"
        );
        balances[_from] -= amount;
        balances[_to] += amount;
        emit Transfer(_from, _to, amount);
        return true;
    }

    /**
     * This function transfers a specified amount of tokens from the sender's address to a given address.
     */
    function transfer(
        address _to,
        uint256 _amount
    ) public virtual returns (bool) {
        return _transfer(msg.sender, _to, _amount);
    }
}