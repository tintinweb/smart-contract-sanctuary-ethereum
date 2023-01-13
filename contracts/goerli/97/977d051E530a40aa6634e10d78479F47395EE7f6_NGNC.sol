//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

/**
 * @title Impementation of the NGNC Stable Coin with Blacklist, Burn and Mint Function
 * @dev Implementation of the ERC20 standard token.
 */
contract NGNC {

    string private _name;
    string private _symbol;

    uint8 private _decimals;
    uint256 private _totalSupply;
    
    address public owner;

    mapping(address => uint) private _balanceOf;

    mapping(address => mapping(address => uint)) private _allowed;

    event Transfer (
        address indexed _from, 
        address indexed _to, 
        uint256 _value
    );

    event Approval (
        address indexed _owner, 
        address indexed _spender, 
        uint256 _value
    );

    // modifier to check if the caller is owner.
    modifier onlyOwner() {
        require(msg.sender == owner, "Not an owner");
        _;
    }

    /**
     * @dev Set the values for {_name}, {_symbol}, {_decimals}, and {_totalSupply}.
     */
    constructor (
        string memory name_,
        string memory symbol_, 
        uint8 decimals_, 
        uint256 initialSupply_
    ) {
        owner = msg.sender;
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _balanceOf[msg.sender] = initialSupply_;
        _totalSupply = initialSupply_;
    }

    /**
     * @dev Return the token name.
     * @return A string representing the name of the token
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Return the token symbol.
     * @return A string representing the symbol of the token.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Return the number of decimals used to represent the token.
     * @return An uint8 representing the decimals used for display purposes.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev Return the total number of tokens in existence.
     * @return An uint256 representing the total existed tokens
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    /**
     * @dev Return the amount of tokens owned by a account.
     * @param _owner address to query the balance of.
     * @return An uint256 representing the token amount owned by the passed address
     */
    function balanceOf(address _owner) public view returns (uint256) {
        return _balanceOf[_owner];
    }

    /**
     * @dev Transfer tokens to a specified address.
     * @param _to address To which token is transferred.
     * @param _value uin256 The amount of tokens to be transferred.
     * @return success boolean indicating the transactions suceeded.
     */
    function transfer(address _to, uint256 _value) public payable returns (bool success) {
        require(_to != address(0), "Transfer to the zero address!");
        require(_balanceOf[msg.sender] >= _value, "Insufficient tokens!");
        _balanceOf[_to] += _value;
        _balanceOf[msg.sender] -= _value;

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another.
     * @param _from address from which you want to send tokens.
     * @param _to address to which token is transferred.
     * @param _value uint256 amount of tokens to be transferred.
     * @return success boolean indicating the trasaction succeeded.
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0), "Transfer to the zero address!");
        require(_balanceOf[_from] >= _value, "Insufficient tokens!");
        require(_allowed[_from][msg.sender] >= _value, "Insufficient allowance!");
        
        _balanceOf[_from] -= _value;
        _balanceOf[_to] += _value;
        _allowed[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens.
     * @param _spender address which will spend the funds on behalf of the caller.
     * @param _value uint256 amount of tokens to be spent.
     * @return success boolean indicating the trasaction succeeded.
     */
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_spender != address(0), "Approve to the zero address!");
        require(_value == 0 || _allowed[msg.sender][_spender] == 0);
        _allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @dev Check the amount of tokens that an _owner allowed to a _spender.
     * @param _owner address which owns the funds.
     * @param _spender address which will spend the funds.
     * @return remaining uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return _allowed[_owner][_spender];
    }

    /**
     * @dev Mint an amount of the token and assigns it to specfied account,
     * increasing the total supply
     * @param _to address which will receive the created tokens.
     * @param _value uint256 amount that will be created.
     */
    function mint(address _to , uint256 _value) public onlyOwner {
        require(_to != address(0), "Mint to the zero address!");
        _totalSupply += _value;
        _balanceOf[_to] += _value;

        emit Transfer(address(0), _to, _value);
    }
    
    /**
     * @dev Burn an amount of the token of the caller, reducing the total supply
     * @param _value uint256 amount that will be burnt.
     */
    function burn(uint256 _value) public onlyOwner{
        require(_balanceOf[msg.sender] >= _value, "Burn amount exceeds balance!");
        _totalSupply -= _value;
        _balanceOf[msg.sender] -= _value;

        emit Transfer(msg.sender, address(0), _value);
    }

    /**
     * @dev Burn an amount of the token of a given account, 
     * reducing the total supply and allowance.
     * @param _from address whose tokens will be burnt.
     * @param _value uint256 amount that will be burnt.
     */
    function burnFrom(address _from, uint256 _value) public {
        require(_from != address(0), "Burn from the zero address!");
        require(_balanceOf[_from] >= _value, "Burn amount exceeds balance!");
        require(_allowed[_from][msg.sender] >= _value, "Insufficient allowance!");

        _totalSupply -= _value;
        _balanceOf[_from] -= _value;
        _allowed[_from][msg.sender] -= _value;

        emit Transfer(_from, address(0), _value);
    }

    mapping(address => bool) private _blacklist;

    function isBlacklisted(address _address) public view returns (bool) {
        return _blacklist[_address];
    }

    function addToBlacklist(address _address) public onlyOwner {
        _blacklist[_address] = true;
    }

    function removeFromBlacklist(address _address) public onlyOwner {
        _blacklist[_address] = false;
    }

}

// Cross NGNC,NGNC,18,100000000000000000000000000