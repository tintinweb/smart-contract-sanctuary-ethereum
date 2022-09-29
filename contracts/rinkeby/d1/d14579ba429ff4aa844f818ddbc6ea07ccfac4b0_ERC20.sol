// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
 
import "./IERC20.sol";
import "./IERC20Metadata.sol";
contract ERC20 is IERC20, IERC20Metadata {
    // 地址余额
    mapping(address => uint256) private _balances;
    // 授权地址余额
    mapping(address => mapping(address => uint256)) private _allowances;
 
    uint256 private _totalSupply;
 
    string private _name;
    string private _symbol;
 
    // 设定代币名称符号，并初始化铸造了10000000000代币在发布者帐号下。
    constructor() {
        _name = "HarryToken";
        _symbol = "HYT";
        _mint(msg.sender, 10000000000);
    }
 
    function name() public view virtual override returns (string memory) {
        return _name;
    }
 
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
 
    /// 小数点位数一般为 18
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }
 
    // 返回当前流通代币的总量
    function totalSupply() public view virtual  override returns (uint256) {
        return _totalSupply;
    }
 
    // 查询指定帐号地址余额
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }
 
    // 转帐功能
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
    }
 
    // 获取被授权者可使用授权帐号的可使用余额
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }
 
    // 授权指定帐事情可使用自己一定额度的帐户余额。
    // 授权spender, 可将自己余额。使用可使用的余额的总量为amount
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, amount);
        return true;
    }
 
    //approve函数中的spender调用，将授权人 from 帐户中的代币转入to 帐户中
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }
 
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }
 
    function decreaseAllowance(address spender, uint256 substractedValue) public virtual returns (bool) {
        address owner = msg.sender;
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= substractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - substractedValue);
        }
        return true;
    }
 
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
 
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
 
        _beforeTokenTransfer(address(0), account, amount);
 
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
 
        _afterTokenTransfer(address(0), account, amount);
    }
 
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
 
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve  to the zero address");
 
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
 
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
 
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
 
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}