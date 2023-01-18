// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "./ERC20Interface.sol";
import "./Pausable.sol";

contract Tava is ERC20Interface, Pausable{
    
    string private _name = "TAVA";
    string private _symbol = "TAVA";
    uint8 private _decimals = 18;
    uint256 private _totalSupply; 

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    /* ERC20Interface Implements */
    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

     function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public whenNotPaused override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal whenNotPaused virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(sender, recipient, amount);
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        _afterTokenTransfer(sender, recipient, amount);
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
         return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public whenNotPaused override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal whenNotPaused virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

// mint하고 timelock contract에 토큰 입금 (transferfrom 사용) 
    function transferFrom(address sender, address recipient, uint256 amount) public whenNotPaused override returns (bool) {
         _transfer(sender, recipient, amount);
         uint256 currentAllowance = _allowances[sender][msg.sender];
         require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
         unchecked {
         _approve(sender, msg.sender, currentAllowance - amount);
        }
        return true;
    }

    function _mint(address account, uint256 amount) internal whenNotPaused virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(address(0), account, amount);
        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
        _afterTokenTransfer(address(0), account, amount);
    }

    /*added mint function*/
    function mint (address account, uint256 amount) external whenNotPaused onlyOwner{
        require(msg.sender == account);
        _mint(account, amount);
    }

    function _burn(address account, uint256 amount) internal whenNotPaused virtual {
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

    /*added burn function*/
    function burn (address account, uint256 amount) public whenNotPaused onlyOwner{
        require (msg.sender == account );
        _burn(account, amount);
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