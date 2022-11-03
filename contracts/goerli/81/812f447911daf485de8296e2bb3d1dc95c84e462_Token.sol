//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

abstract contract ERC20Token {
    //functions
    function name() public view virtual returns (string memory);

    function symbol() public view virtual returns (string memory);

    function decimals() public view virtual returns (uint256);

    function totalSupply() public view virtual returns (uint256);

    function balanceOf(address _owner) public view virtual returns (uint256 balance);

    function transfer(address _to, uint256 _value) public virtual returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public virtual returns (bool success);

    function approve(address _spender, uint256 _value) public virtual returns (bool success);

    function allowance(address _owner, address _spender) public view virtual returns (uint256 remaining);

    //Events
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

//This contract manage onwer of the contract
contract owned {
    // /**Events */
    event ownerChanged(address indexed oldOwner, address indexed owner);
    address private owner;

    constructor() {
        owner = msg.sender;
        emit ownerChanged(address(0), owner);
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Only owner can call this function");
        _;
    }

    //TransferOwnerShip
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        owner = _newOwner;
        emit ownerChanged(msg.sender, _newOwner);
    }

    // return current owner of the contract
    function getOwner() public view returns (address) {
        return owner;
    }
}

//ERC20 Toekn implementation
contract Token is owned, ERC20Token {
    /** State Variables*/
    string private _name;
    string private _symbol;
    uint256 private _decimal;
    uint256 private _totalSupply;
    address private _minter;

    /**Mappings*/
    mapping(address => uint256) private _balance;
    mapping(address => mapping(address => uint256)) private _allowances;

    /** Constructor*/
    constructor() {
        _name = "Flat";
        _symbol = "FT";
        _decimal = 18;
        _totalSupply = 1000000 * 10**18;
        _minter = msg.sender;
        _balance[_minter] = _totalSupply;
    }

    //Getter functions
    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public view override returns (uint256) {
        return _decimal;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _owner) public view override returns (uint256 balance) {
        return _balance[_owner];
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    /*
     *This function transfer token from one address to another adddress
     */
    function _transfer(
        address _from,
        address _to,
        uint256 _value
    ) internal returns (bool success) {
        require(_from != address(0), "Address not Found");
        require(_to != address(0), "Address not Found");
        require(_balance[_from] >= _value, "You don't have enough balance");
        _balance[_from] -= _value;
        _balance[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    //Onwer transfer tokens to receiver
    function transfer(address _to, uint256 _value) public override returns (bool success) {
        address owner = msg.sender;
        _transfer(owner, _to, _value);
        return true;
    }

    //Third party which owner allowed to transfer token
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public override returns (bool success) {
        address spender = msg.sender;
        _spenderAllowance(_from, spender, _value);
        _transfer(_from, _to, _value);
        return true;
    }

    //This function approve spender to spend allowed tokens
    function approve(address _spender, uint256 _value) public override returns (bool success) {
        address owner = msg.sender;
        _approve(owner, _spender, _value);
        return true;
    }

    //approve function
    function _approve(
        address owner,
        address spender,
        uint256 _value
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = _value;
        emit Approval(owner, spender, _value);
    }

    //Check if spender have enough tokens.
    function _spenderAllowance(
        address from,
        address spender,
        uint256 _value
    ) internal {
        uint256 currentAllowance = allowance(from, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= _value, "ERC20: insufficient allowance");
            unchecked {
                _approve(from, spender, currentAllowance - _value);
            }
        }
    }

    //Increase allowance of spender
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    //Decrease allowance of spender
    function decreaseAllowance(address spender, uint256 removeValue) public virtual returns (bool) {
        address owner = msg.sender;
        require(allowance(owner, spender) >= removeValue, "ERC20: decreased allowance below zero");
        _approve(owner, spender, allowance(owner, spender) - removeValue);
        return true;
    }

    //Owner can mint unlimited tokens
    function mint(address account, uint256 amount) public onlyOwner {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply += amount;
        _balance[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    //Any one can burn thier tokens
    function burn(address account, uint256 amount) public {
        require(account != address(0), "ERC20: mint to the zero address");
        _totalSupply -= amount;
        _balance[account] -= amount;
        emit Transfer(account, address(0), amount);
    }
}