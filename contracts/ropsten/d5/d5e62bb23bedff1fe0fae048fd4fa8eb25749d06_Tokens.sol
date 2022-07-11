/**
 *Submitted for verification at Etherscan.io on 2022-07-10
*/

/**
 *Submitted for verification at Etherscan.io on 2022-07-10
*/

pragma solidity ^0.8.7;


interface IERC20 {
    event Transfer(address indexed sender, address indexed spender, uint256 value);
    event Approval(address indexed sender, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address sender, address spender) external view returns (uint256);
    function approve(address recipient, uint256 amount) external returns (bool);
}

contract Tokens is IERC20 {
    mapping (address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    uint8 private _decimals;
    string private _name;
    string private _symbol;
    address payable private _owner;

modifier onlyOwner(){
        require(msg.sender == _owner, "Only owner can call this function");
        _;
    }

    constructor (string memory name_, string memory symbol_, address payable owner_) {
        _name = name_;
        _symbol = symbol_;
        _owner = owner_;
        _decimals = 0;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function decimals() external view returns (uint8) {
    return _decimals;
    }
    
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function owner() public view virtual returns (address ) {
        return _owner;
    }
    
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address sender, address spender) public view virtual override returns (uint256) {
        return _allowances[sender][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address sender = msg.sender;
        _approve(sender, spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address sender = msg.sender;
        _approve(sender, spender, allowance(sender, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address sender = msg.sender;
        uint256 currentAllowance = allowance(sender, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(sender, spender, currentAllowance - subtractedValue);
        }
        return true;
    }

    function _approve(
        address sender,
        address spender,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[sender][spender] = amount;
        emit Approval(sender, spender, amount);
    }

    function _spendAllowance(
        address sender,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(sender, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(sender, spender, currentAllowance - amount);
            }
        }
    }
   
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }
    
    function mint(uint256 amount) onlyOwner public virtual {

        _totalSupply += amount;
        _balances[_owner] += amount;
        emit Transfer(msg.sender, address(0), (amount));
      
    }

    function burn(address recipient, uint amount) onlyOwner external {
        _balances[recipient] -= amount;
        _totalSupply -= amount;
        emit Transfer(msg.sender, recipient, amount);
    }
    
}