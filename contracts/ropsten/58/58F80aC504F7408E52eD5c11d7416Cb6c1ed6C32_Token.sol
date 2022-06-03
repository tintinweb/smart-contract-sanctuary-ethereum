// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./IToken.sol";
import "./Context.sol";
import "./Ownable.sol";
import "./SafeMath.sol";



contract Token is IToken, Context, Ownable{

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    uint8 private _decimals;
    string private _symbol;
    string private _name;
    uint256 private _cap;

    constructor(string memory TOKEN_NAME, string memory TOKEN_SYMBOL, uint8 DECIMALS, uint256 TOTAL_SUPPLY, uint256 CAP)  {
        _name = TOKEN_NAME;
        _cap = CAP;
        _decimals = DECIMALS;
        _symbol = TOKEN_SYMBOL;
        _totalSupply = TOTAL_SUPPLY;

        address msgSender = _msgSender();
        _balances[msgSender] = _totalSupply;
        emit Transfer(address(0), msgSender, _totalSupply);
    }

        
    function getOwner() external view override returns (address) {
        return _msgSender();
    }

    function decimals() external view override returns (uint8) {
        return _decimals;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function name() external view override returns (string memory) {
        return _name;
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }


    function transfer(address recipient, uint256 amount) external override returns (bool){
        _transfer(_msgSender(), recipient, amount);
        return true;
    }


    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

 
    function approve(address spender, uint256 amount) external override returns (bool){
        _approve(_msgSender(), spender, amount);
         return true;
    }


    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), SafeMath.sub(_allowances[sender][_msgSender()], amount, "BEP20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, SafeMath.add(_allowances[_msgSender()][spender], addedValue));
        return true;
    }

     function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, SafeMath.sub(_allowances[_msgSender()][spender], subtractedValue, "BEP20: decreased allowance below zero"));
        return true;
    }

    function mint(uint256 amount) public onlyOwner returns (bool) {
        _mint(_msgSender(), amount);
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "BEP20: transfer from the zero address");
        require(recipient != address(0), "BEP20: transfer to the zero address");

        _balances[sender] = SafeMath.sub(_balances[sender], amount, "BEP20: transfer amount exceeds balance");
        _balances[recipient] = SafeMath.add(_balances[recipient], amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: mint to the zero address");

        _totalSupply = SafeMath.add(_totalSupply, amount);
        _balances[account] = SafeMath.add(_balances[account], amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: burn from the zero address");

        _totalSupply = SafeMath.sub(_totalSupply, amount);
        _balances[account] = SafeMath.sub(_balances[account], amount, "BEP20: burn amount exceeds balance");
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function burnFrom(address account, uint256 amount) public onlyOwner{
        _burn(account, amount);
        _approve(account, _msgSender(), SafeMath.sub(_allowances[account][_msgSender()], amount, "BEP20: burn amount exceeds allowance"));
    }

    function burn(uint256 amount) public onlyOwner{
        _burn(_msgSender(), amount);
    }

    function MintCap(uint256 amount) public onlyOwner{
        require(_cap > 0, "ERC20Capped: cap is 0");
        _mintCap(_msgSender(), amount, _cap);
    }

    function _mintCap(address account, uint256 amount, uint256 cap) internal {
        require(_totalSupply + amount <= cap, "ERC20Capped: cap exceeded");
        _mint(account, amount);
    }


}