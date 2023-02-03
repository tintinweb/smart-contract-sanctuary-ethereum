//smart contract for the ERC20 token NurKoin
//SPDX-License-Identifier: UNLICENSED
//Authors: Alessandro Frizzoni, Claudio Baldassarri, Fabio Persichetti

pragma solidity ^0.8.0;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to,  uint256 amount) external returns (bool);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}


contract NUR is IERC20, IERC20Metadata {
    address private _owner;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    mapping(address => uint256) private _frozenAddresses;

    constructor() {
        _owner = msg.sender;
        _name = "NurKoin";
        _symbol = "NUR";
        _totalSupply = 22000000000 * 1 ether;     
        _balances[msg.sender] = _totalSupply;    
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view   returns (address) {
        return _owner;
    }

    function _checkOwner() internal view  {
        require(owner() == msg.sender , "ERROR: caller is not the owner");
    }

    function transferOwnership(address newOwner) public  onlyOwner {
        require(newOwner != address(0), "ERROR: new owner is the zero address");
        _owner = newOwner;
    }
    
    function name() public view  override returns (string memory) {
        return _name;
    }

    function symbol() public view  override returns (string memory) {
        return _symbol;
    }

    function decimals() public pure override returns (uint8) {
        return 18;
    }

    function totalSupply() public view  override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view  override returns (uint256) {
        return _balances[account];
    }
    
    function transfer(address to, uint256 amount) public  override returns (bool) {
        address ms = msg.sender;
        _transfer(ms, to, amount);
        return true;
    }

    function allowance(address tokenOwner, address spender) public view  override returns (uint256) {
        return _allowances[tokenOwner][spender];
    }

    function approve(address spender, uint256 amount) public  override returns (bool) {
        address ms = msg.sender;
        _approve(ms, spender, amount);
        return true;
    }
   
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public  override returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }


    function increaseAllowance(address spender, uint256 addedValue) public  returns (bool) {
        address ms = msg.sender;
        _approve(ms, spender, allowance(ms, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public  returns (bool) {
        address ms = msg.sender;
        uint256 currentAllowance = allowance(ms, spender);
        require(currentAllowance >= subtractedValue, "decreased allowance below zero");
        unchecked {
            _approve(ms, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal  {
        require(from != address(0), "transfer from the zero address");
        require(to != address(0), "transfer to the zero address");
        require(!isFrozen(from), "from is frozen");
        require(!isFrozen(to), "to is frozen");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

    }

    
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "burn from the zero address");

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

    }

    function burn(address account, uint256 amount) public onlyOwner {
        _burn(account, amount);
    }
    
    function _approve(
        address tokenOwner,
        address spender,
        uint256 amount
    ) internal  {
        require(tokenOwner != address(0), "approve from the zero address");
        require(spender != address(0), "approve to the zero address");

        _allowances[tokenOwner][spender] = amount;
        emit Approval(tokenOwner, spender, amount);
    }

    
    function _spendAllowance(
        address tokenOwner,
        address spender,
        uint256 amount
    ) internal  {
        uint256 currentAllowance = allowance(tokenOwner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "insufficient allowance");
            unchecked {
                _approve(tokenOwner, spender, currentAllowance - amount);
            }
        }
    }

    
    function freeze(address account) public onlyOwner {
        require(account != address(0), "freezing the zero address");       
        _frozenAddresses[account] = 1 ;  
    }

    function unfreeze(address account) public onlyOwner {
        require(account != address(0), "freezing the zero address");       
        _frozenAddresses[account] = 0;   
    }

    function isFrozen(address account) public view returns (bool) {
       if  (_frozenAddresses[account] == 1)  { return true;}
       return false;
    }

}