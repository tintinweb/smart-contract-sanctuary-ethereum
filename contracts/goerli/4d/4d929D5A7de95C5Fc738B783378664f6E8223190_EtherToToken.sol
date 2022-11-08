//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface ERC20Interface {
  function name() external view returns (string memory);
  function symbol() external view returns (string memory);
  function totalSupply() external view returns (uint256);
  function decimals() external view returns (uint8);
  function balanceOf(address _owner) external view returns (uint256 balance);
  function transfer(address _to, uint256 _amount) external returns (bool success);
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
  function approve(address _spender, uint256 _value) external returns (bool success);
  function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}
//0x4d929D5A7de95C5Fc738B783378664f6E8223190
contract EtherToToken is ERC20Interface {

  mapping(address => uint256) private _balances;
  mapping(address => mapping(address => uint256)) private _allowances;

  uint256 private _totalSupply; //This are tokens

  string private _name;
  string private _symbol;

  constructor() {
    _name = "ERC20-TOKEN";
    _symbol = "ERCTK";
    _totalSupply = 100000; //100000 tokens
  }

  event Transfer(address indexed _from, address indexed _to, uint256 _amount);
  event Approval(address indexed _owner, address indexed _spender, uint256 _amount);


  function transferEtherToToken(uint256 _amount) public payable {
    uint256 senderBalance = _balances[msg.sender];
    
    require(senderBalance >= _amount, "Transfer Failed: Not enough balance.");

    _totalSupply += _amount; //_amount is added to totalsupply i.e it is minted 
    _balances[msg.sender] += _amount; //New minted token is added to the user

    emit Transfer(msg.sender, msg.sender, _amount);
  }

  /*************** Below are standard ERC20 Tokens standard function  *****************************/
  function name() public view virtual override returns (string memory) {
      return _name;
  }
    
  function symbol() public view virtual override returns (string memory) {
      return _symbol;
  }

  function decimals() public view virtual override returns (uint8) {
      return 18;
  }

  function totalSupply() public view virtual override returns (uint256) {
      return _totalSupply;
  }

  function balanceOf(address account) public view virtual override returns (uint256) {
      return _balances[account];
  }

  function allowance(address owner, address spender) public view virtual override returns (uint256) {
      return _allowances[owner][spender];
  }

  function transfer(address to, uint256 amount) public virtual override returns (bool) {
    address from = msg.sender;
    _transfer(from, to, amount);
    return true;
  }

  function transferFrom(address from, address to, uint256 amount ) public virtual override returns (bool) {
      address spender = msg.sender;
      _spendAllowance(from, spender, amount);
      _transfer(from, to, amount);
      return true;
  }

  function _transfer(address from, address to, uint256 amount ) internal virtual {
    require(from != address(0), "ERC20: transfer from the zero address");
    require(to != address(0), "ERC20: transfer to the zero address");

    uint256 fromBalance = _balances[from];
    require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
      
    // Overflow not possible: the sum of all balances is capped by totalSupply
    unchecked {
      _balances[from] = fromBalance - amount;
      _balances[to] += amount;
    }

    emit Transfer(from, to, amount);
  }

  function _spendAllowance( address owner, address spender, uint256 amount ) internal virtual {
    uint256 currentAllowance = allowance(owner, spender);
    if (currentAllowance != type(uint256).max) {
        require(currentAllowance >= amount, "ERC20: insufficient allowance");
        unchecked {
            _approve(owner, spender, currentAllowance - amount);
        }
    }
  }


  function approve(address spender, uint256 amount) public virtual override returns (bool) {
    address owner = msg.sender;
    _approve(owner, spender, amount);
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
}