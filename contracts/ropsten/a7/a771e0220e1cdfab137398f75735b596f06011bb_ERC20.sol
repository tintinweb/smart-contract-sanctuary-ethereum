// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./Context.sol";
contract ERC20 is Context, IERC20, IERC20Metadata
{
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _initialSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimal;
     
    constructor() {
         
        _name = "REDBIT";
        _symbol = "RBT";
         _decimal = 16;
         _initialSupply = 10**12;

    }

  
    function name() public view virtual override returns (string memory) {
        return _name;
    }

  
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

   
    function decimals() public view virtual override returns (uint8) {
        return _decimal;
    }
    function totalSupply() public view virtual override returns (uint256) {
        return _initialSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }


   
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

 
    function allowance(address owner, address stackholders) public view virtual override returns (uint256) {
        return _allowances[owner][stackholders];
    }

    function approve(address stackholders, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, stackholders, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address stackholders = _msgSender();
        _spendAllowance(from, stackholders, amount);
        _transfer(from, to, amount);
        return true;
    }
    function increaseAllowance(address stackholders, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, stackholders, allowance(owner, stackholders) + addedValue);
        return true;
    }
    function decreaseAllowance(address stackholders, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, stackholders);
        require(currentAllowance >= subtractedValue);
        unchecked {
            _approve(owner, stackholders, currentAllowance - subtractedValue);
        }

        return true;
    }

   
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0));
        require(to != address(0));

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount);
        unchecked {
            _balances[from] = fromBalance - amount;
            
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    
    function _mint(address account, uint256 amount) private  {
        require(account != address(0), "only call by owner");

        _beforeTokenTransfer(address(0), account, amount);

      _initialSupply += amount;
        unchecked {
           
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

   
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "Call by both owner and stackholders");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "Call by both owner and stackholders");
        unchecked {
            _balances[account] = accountBalance - amount;
           
            _initialSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

   
    function _approve(
        address owner,
        address stackholders,
        uint256 amount
    ) internal virtual {
        require(owner != address(0));
        require(stackholders != address(0));

        _allowances[owner][stackholders] = amount;
        emit Approval(owner, stackholders, amount);
    }

  
    function _spendAllowance(
        address owner,
        address stackholders,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, stackholders);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount);
            unchecked {
                _approve(owner, stackholders, currentAllowance - amount);
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