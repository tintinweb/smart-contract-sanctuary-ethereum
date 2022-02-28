/**
 *Submitted for verification at Etherscan.io on 2022-02-28
*/

// File: math/SafeMath.sol

pragma solidity 0.5.17;


library SafeMath {
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    require(c >= a, "SafeMath: addition overflow");
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
    require(b <= a, "SafeMath: subtraction overflow");
    return a - b;
  }

  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }

    c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Since Solidity automatically asserts when dividing by 0,
    // but we only need it to revert.
    require(b > 0, "SafeMath: division by zero");
    return a / b;
  }

  function mod(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Same reason as `div`.
    require(b > 0, "SafeMath: modulo by zero");
    return a % b;
  }
}

// File: token/erc20/IERC20.sol

pragma solidity 0.5.17;


interface IERC20 {
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  function totalSupply() external view returns (uint256 _supply);
  function balanceOf(address _owner) external view returns (uint256 _balance);

  function approve(address _spender, uint256 _value) external returns (bool _success);
  function allowance(address _owner, address _spender) external view returns (uint256 _value);

  function transfer(address _to, uint256 _value) external returns (bool _success);
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool _success);
}

// File: token/erc20/ERC20.sol

pragma solidity 0.5.17;




contract ERC20 is IERC20 {
  using SafeMath for uint256;

  uint256 public totalSupply;
  mapping (address => uint256) public balanceOf;
  mapping (address => mapping (address => uint256)) internal _allowance;

  function approve(address _spender, uint256 _value) public returns (bool) {
    _approve(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public view returns (uint256) {
    return _allowance[_owner][_spender];
  }

  function increaseAllowance(address _spender, uint256 _value) public returns (bool) {
    _approve(msg.sender, _spender, _allowance[msg.sender][_spender].add(_value));
    return true;
  }

  function decreaseAllowance(address _spender, uint256 _value) public returns (bool) {
    _approve(msg.sender, _spender, _allowance[msg.sender][_spender].sub(_value));
    return true;
  }

  function transfer(address _to, uint256 _value) public returns (bool _success) {
    _transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool _success) {
    _transfer(_from, _to, _value);
    _approve(_from, msg.sender, _allowance[_from][msg.sender].sub(_value));
    return true;
  }

  function _approve(address _owner, address _spender, uint256 _amount) internal {
    require(_owner != address(0), "ERC20: approve from the zero address");
    require(_spender != address(0), "ERC20: approve to the zero address");

    _allowance[_owner][_spender] = _amount;
    emit Approval(_owner, _spender, _amount);
  }

  function _transfer(address _from, address _to, uint256 _value) internal {
    require(_from != address(0), "ERC20: transfer from the zero address");
    require(_to != address(0), "ERC20: transfer to the zero address");
    require(_to != address(this), "ERC20: transfer to this contract address");

    balanceOf[_from] = balanceOf[_from].sub(_value);
    balanceOf[_to] = balanceOf[_to].add(_value);
    emit Transfer(_from, _to, _value);
  }
}

// File: token/erc20/IERC20Detailed.sol

pragma solidity 0.5.17;


interface IERC20Detailed {
  function name() external view returns (string memory _name);
  function symbol() external view returns (string memory _symbol);
  function decimals() external view returns (uint8 _decimals);
}

// File: token/erc20/ERC20Detailed.sol

pragma solidity 0.5.17;




contract ERC20Detailed is ERC20, IERC20Detailed {
  string public name;
  string public symbol;
  uint8 public decimals;

  constructor(string memory _name, string memory _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}

// File: access/HasAdmin.sol

pragma solidity 0.5.17;


contract HasAdmin {
  event AdminChanged(address indexed _oldAdmin, address indexed _newAdmin);
  event AdminRemoved(address indexed _oldAdmin);

  address public admin;

  modifier onlyAdmin {
    require(msg.sender == admin, "HasAdmin: not admin");
    _;
  }

  constructor() internal {
    admin = msg.sender;
    emit AdminChanged(address(0), admin);
  }//初始化设置权限

  function changeAdmin(address _newAdmin) external onlyAdmin {
    require(_newAdmin != address(0), "HasAdmin: new admin is the zero address");//判断权限转移地址是否为空
    emit AdminChanged(admin, _newAdmin);
    admin = _newAdmin;
  }//权限转移

  function removeAdmin() external onlyAdmin {
    emit AdminRemoved(admin);
    admin = address(0);
  }
}//移除权限

// File: access/HasMinters.sol

pragma solidity 0.5.17;



contract HasMinters is HasAdmin {
  event MinterAdded(address indexed _minter);
  event MinterRemoved(address indexed _minter);

  address[] public minters;
  mapping (address => bool) public minter;

  modifier onlyMinter {
    require(minter[msg.sender]);
    _;
  }

  function addMinters(address[] memory _addedMinters) public onlyAdmin { //增加矿工
    address _minter;

    for (uint256 i = 0; i < _addedMinters.length; i++) {
      _minter = _addedMinters[i];

      if (!minter[_minter]) { //判断该地址是否是矿工，若不是则增加为矿工
        minters.push(_minter);
        minter[_minter] = true;
        emit MinterAdded(_minter);//触发矿工增加事件
      }
    }
  }

  function removeMinters(address[] memory _removedMinters) public onlyAdmin { //删除矿工
    address _minter;

    for (uint256 i = 0; i < _removedMinters.length; i++) {
      _minter = _removedMinters[i];

      if (minter[_minter]) { //判断该地址是否为矿工，若是则从名单中删除
        minter[_minter] = false;
        emit MinterRemoved(_minter);//触发矿工删除事件
      }
    }

    uint256 i = 0;

    while (i < minters.length) {
      _minter = minters[i];

      if (!minter[_minter]) { //判断该地址是否为矿工，若不是则矿工数量相应减少
        minters[i] = minters[minters.length - 1];
        delete minters[minters.length - 1];
        minters.length--;
      } else { //若该地址是矿工，则矿工数量相应增加
        i++;
      }
    }
  }

  function isMinter(address _addr) public view returns (bool) { //判断矿工资格
    return minter[_addr];
  }
}

// File: token/erc20/ERC20Mintable.sol

pragma solidity 0.5.17;




contract ERC20Mintable is HasMinters, ERC20 {
  function mint(address _to, uint256 _value) public onlyMinter returns (bool _success) { //铸币
    return _mint(_to, _value);
  }

  function _mint(address _to, uint256 _value) internal returns (bool success) {
    totalSupply = totalSupply.add(_value); //代币总量增加铸币的数额
    balanceOf[_to] = balanceOf[_to].add(_value); //矿工账户增加铸币的数额
    emit Transfer(address(0), _to, _value); //触发铸币转账事件
    return true;
  }
}

// File: HealthPotion.sol

pragma solidity 0.5.17;



contract HealthPotion is ERC20Detailed, ERC20Mintable {
  constructor()
    public
    ERC20Detailed("Health Potion", "HEP", 0)
  {
    address[] memory _minters = new address[](1);
    _minters[0] = msg.sender;
    addMinters(_minters);
    _mint(msg.sender, 2100000000);
  }//合约初始化，代币总量为2100000000个代币
}