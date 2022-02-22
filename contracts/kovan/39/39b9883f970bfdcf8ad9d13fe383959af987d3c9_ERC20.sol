//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

import "./IERC20.sol";

contract ERC20 is IERC20
{
    address public owner; 
    uint256 public constant INITIAL_SUPPLY = 1000000000; // one billion


    string private _name;
    string private _symbol;

    uint256 _totalSupply;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;



    modifier onlyOwner()
    {
        require(msg.sender == owner, "ERC20: account is not an owner");
        _;
    }


    constructor(string memory name_, string memory symbol_) 
    {
        _name = name_;
        _symbol = symbol_;
        owner = msg.sender;


        // one bl with 18 decimals
        _totalSupply = INITIAL_SUPPLY * 10**decimals();
        _balances[owner] = _totalSupply;
    }



    // view data

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
    
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function totalSupply() public virtual override view returns (uint256){
        return _totalSupply;
    }




    // transfer functionality

    function transfer(address to, uint256 amount) 
    public 
    virtual 
    override 
    returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }



    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) 
    public
    virtual
    override
    returns (bool) {
        uint256 currentAllowance = _allowances[from][to];
        require(currentAllowance >= amount, "ERC20: insufficient allowance");


        // decrease allowance
        _approve(from, to, currentAllowance - amount);

        _transfer(from, to, amount);
        return true;
    }



    function allowance(address from, address to) 
    public 
    view 
    virtual 
    override 
    returns (uint256) {
        return _allowances[from][to];
    }



    function approve(
        address to,
        uint256 amount
    ) 
    public
    override
    virtual
    returns(bool) {
        _approve(msg.sender, to, amount);
        return true;
    }




    function increaseAllowance(address to, uint256 value) 
    public 
    virtual 
    returns (bool) {
        _approve(msg.sender, to, _allowances[owner][to] + value);
        return true;
    }



    function decreaseAllowance(address to, uint256 value) 
    public
    virtual
    returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][to];
        require(currentAllowance >= value, "ERC20: decreased allowance below zero");
        
        unchecked
        {
            currentAllowance -= value;
        }

        _approve(msg.sender, to, currentAllowance);
        
        return true;
    }





    function mint(address account, uint256 amount) 
    public 
    virtual 
    onlyOwner {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;
        
        emit Mint(address(0), account, amount);
    }


    function burn(address account, uint256 amount) 
    public 
    virtual 
    onlyOwner {
        require(account != address(0), "ERC20: burn from the zero address");
        require(_balances[account] >= amount, "ERC20: burn amount exceeds balance");
        
        unchecked {
            _balances[account] -= amount;
        }
        _totalSupply -= amount;

        emit Burn(account, address(0), amount);
    }





    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(_balances[from] >= amount, "ERC20: transfer amount exceeds balance");
        
        unchecked {
            _balances[from] -= amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);
    }


     function _approve(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(from != address(0), "ERC20: approve to the zero address");
        require(to != address(0), "ERC20: approve to the zero address");

        _allowances[from][to] = amount;
        emit Approval(msg.sender, to, amount);
    }
}