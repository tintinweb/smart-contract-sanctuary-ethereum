pragma solidity ^0.8.17;

contract ERC20 {

  string public _name;
  string public _symbol;
  uint256 public _totalSupply;

  mapping(address => uint256) private _balances;
  mapping(address => mapping(address => uint256)) private _allowances;

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);


  constructor(string memory name_, string memory symbol_) {
    _name = name_;
    _symbol = symbol_;
    _mint(msg.sender, 1000 * 10 ** 18);
  }

  function _mint(address account, uint256 amount) internal {
    require(account != address(0));
    _totalSupply = _totalSupply + amount;
    _balances[account] = _balances[account] + amount;
    emit Transfer(address(0), account, amount);
  }

  function name() public view returns (string memory){
    return _name;
  }


  function symbol() public view returns (string memory) {
    return _symbol;
  }


  function decimals() public view returns (uint8) {
    return 18;
  }


  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }


  function balanceOf(address _owner) public view returns (uint256 balance) {
    return _balances[_owner];
  }


  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    return _allowances[_owner][_spender];
  }


  function transfer(address _to, uint256 _amount) public returns (bool success) {
    address owner = msg.sender;
    _transfer(owner, _to, _amount);
    return true;
  }


  function _transfer(address from, address to, uint256 amount) public {
    require(from != address(0), "ERC20: transfer from the zero address");
    require(to != address(0), "ERC20: trnsfer to the zero address");

    _beforeTokenTransfer(from, to, amount);

    uint256 fromBalance = _balances[from];
    require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
    unchecked {
      _balances[from] = fromBalance - amount;
      _balances[to] += amount;
    }

    emit Transfer(from, to, amount);

    _afterTokenTransfer(from, to, amount);

  }


  function _spendAllowance(address owner, address spender, uint256 amount) public {
    uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
  }


  function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {
    address spender = msg.sender;
    _spendAllowance(_from, spender, _amount);
    _transfer(_from, _to, _amount);
    return true;
  }

  function _approve(address owner, address spender, uint256 amount) public {
    require(owner != address(0), "ERC20: approve from the zero address");
    require(spender != address(0), "ERC20: approve to zero address");

    _allowances[owner][spender] = amount;
    emit Approval(owner, spender, amount);
  }

  function approve(address spender, uint256 _amount) public returns (bool success) {
    address owner = msg.sender;
    _approve(owner, spender, _amount);
    return true;
  }


  function _beforeTokenTransfer(address from, address to, uint256 amount) private {}

  function _afterTokenTransfer(address from, address to, uint256 amount) private {}

}