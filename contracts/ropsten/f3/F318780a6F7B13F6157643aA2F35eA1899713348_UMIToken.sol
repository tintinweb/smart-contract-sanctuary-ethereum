/**
 *Submitted for verification at Etherscan.io on 2022-02-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Owned {
    address public _owner;

    constructor () {
        _owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == _owner, "Access denied");
        _;
    }
}

contract Pausable is Owned {
    bool private _paused;

    constructor () {
        _paused = false;
    }

    modifier isPaused {
        require(_paused == false, "Token transfers is paused");
        _;
    }

    function pause() external onlyOwner {
        _paused = true;
    }

    function unpause() external onlyOwner {
        _paused = false;
    }
}

contract Freezing is Owned{
    mapping (address => bool) public frozenAccounts;
    
    event FreezeAccount(address indexed account, bool frozen);
    event UnfreezeAccount(address indexed account);

    modifier isFrozen {
        require(!frozenAccounts[msg.sender], "Your account is currently frozen!");
        _;
    }

    /*Function to freeze an account for transfer tokens
    But he will still be able to make swaps
    */
    function freezeAccount(address _account) public onlyOwner {
        frozenAccounts[_account] = true;
        emit FreezeAccount(_account, true);
    }

    function unfreezeAccount(address _account) public onlyOwner {
        frozenAccounts[_account] = false;
        emit UnfreezeAccount(_account);
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns(string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns(uint8);
}


contract UMIToken is IERC20, IERC20Metadata, Owned, Freezing, Pausable {
    mapping(address => uint256) private _balances;
    mapping(address =>mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;
    //uint256 public _fee;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 public count = 1;

    constructor (
        string memory __name, 
        string memory __symbol, 
        uint256 supply, 
        uint8 __decimals
        ) 
    {
        _decimals = __decimals;
        _name = __name;
        _symbol = __symbol;
        _mint(msg.sender, supply*10**__decimals);
    }

    function name() external view virtual override returns (string memory) {
        return _name;
    }

    function symbol() external view virtual override returns (string memory) {
        return _symbol;
    }

    function totalSupply() external view virtual override returns(uint256) {
        return _totalSupply;
    }

    function decimals() external view virtual override returns (uint8) {
        return _decimals;
    }

    function balanceOf(address _account) public view virtual override returns (uint256) {
        return _balances[_account];
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    //This function mints fixed total supply and can be called only one time by constructor.
    function _mint(address _to, uint256 _amount) internal virtual {
        require(_to != address(0), "Can't mint tokens to 0 address");
        require(count != 0, "Total supply already minted");
        count--;
        _totalSupply += _amount;
        _balances[_to] = _amount;
    }

    function transfer(address _to, uint256 _amount) public virtual override returns(bool) {
        _transfer(msg.sender, _to, _amount);
        return true;
    }

    function transferFrom(address _sender, address _recipient, uint256 _amount) public virtual override returns (bool) {
        uint256 currentAllowance = _allowances[_sender][msg.sender];
        require(currentAllowance >= _amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(_sender, msg.sender, currentAllowance - _amount);
        }
        _transfer(_sender, _recipient, _amount);

        return true;
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address _from, address _to, uint256 _amount) internal virtual isFrozen isPaused {
        require(_from != address(0), "You can't transfer from the zero address");
        require(_to != address(0), "You can't transfer to the zero address");
        require(_balances[_from] >= _amount, "Not enough tokens on balance");
        _balances[_from] -= _amount;
        _balances[_to] += _amount;
        emit Transfer(_from, _to, _amount);
        }
}