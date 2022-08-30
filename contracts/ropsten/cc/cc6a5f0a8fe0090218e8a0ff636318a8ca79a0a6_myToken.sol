// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.16;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./Context.sol";

contract myToken is Context  {
    
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) private _balances;

    string name__ ;
    string symbol__ ;
    uint8 decimals__ ;
    uint256 totalSupply__ ;

    uint256 private _totalSupply;
   

 constructor (string memory __name, string memory __symbol, uint8 __decimals, uint256 __totalSupply ){
       name__ = __name;
       symbol__ = __symbol;
       decimals__ = __decimals;
       totalSupply__ = __totalSupply;
       _balances[msg.sender] = totalSupply__;


   }

    function name() public view virtual  returns (string memory) {
        return name__;
    }
     function symbol() public view virtual  returns (string memory) {
        return symbol__;
    }
    function decimals() public view virtual  returns (uint8) {
        return decimals__;
    }
    function totalSupply() public view virtual  returns (uint256) {
        return totalSupply__;
    }
     function balanceOf(address account) public view virtual  returns (uint256) {
        return _balances[account];
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        
    }
    

    function approve(address spender, uint256 amount) public  returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
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


     function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
       

        _afterTokenTransfer(address(0), account, amount);
    }

     function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        

        _afterTokenTransfer(account, address(0), amount);
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
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

       

        _afterTokenTransfer(from, to, amount);
    }

     function transfer(address to, uint256 amount) public  returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

      function allowance(address owner, address spender) public view  returns (uint256) {
        return _allowances[owner][spender];
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

       function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual  returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }


}