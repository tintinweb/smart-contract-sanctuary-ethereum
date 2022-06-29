/**
 *Submitted for verification at Etherscan.io on 2022-06-28
*/

pragma solidity ^0.8.0;


contract ERC20MaxSupply {
    mapping (address => uint256) private _balances;
    mapping (address => mapping(address => uint256)) private _allowances;
    
    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(string memory name_, string memory symbol_, uint256 maxSupply_) {
        _name = name_;
        _symbol = symbol_;
        _totalSupply = maxSupply_ * 10 ** 18;
        
        _balances[msg.sender] =  maxSupply_ * 10 ** 18;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }
    

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint amount) public returns(bool) {
        address owner = msg.sender;
        _approve(owner, spender, amount);
        return true;
    }

    function approveMax(address spender) public {
        address owner = msg.sender;
        _approve(owner,spender, type(uint256).max);
    }

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

    function _spendAllowance(address owner, address spender, uint256 amount) internal {
        uint256 currentAllowance = _allowances[owner][spender];
        if(currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "Insufficient allowance");
            _allowances[owner][spender] = currentAllowance - amount;
        }
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "Insufficient token balance");
        _balances[from] = fromBalance - amount;
        _balances[to] += amount;

        emit Transfer(from,to,amount);

    }

    function transfer(address to, uint256 amount) public {
        address owner = msg.sender;
        _transfer(owner, to, amount);
    }

    function transferFrom(address from, address to, uint256 amount) public {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
    }
}