/**
 *Submitted for verification at Etherscan.io on 2022-07-11
*/

// File: library/Roles.sol


pragma solidity ^0.8.4;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

  /**
   * @dev give an account access to this role
   */
  function add(Role storage role, address account) internal {
    require(account != address(0));
    role.bearer[account] = true;
  }

  /**
   * @dev remove an account's access to this role
   */
  function remove(Role storage role, address account) internal {
    require(account != address(0));
    role.bearer[account] = false;
  }

  /**
   * @dev check if an account has this role
   * @return bool
   */
  function has(Role storage role, address account)
    internal
    view
    returns (bool)
  {
    require(account != address(0));
    return role.bearer[account];
  }
}

// File: library/Ownable.sol


pragma solidity ^0.8.4;


contract Ownable {
  using Roles for Roles.Role;

  event MinterAdded(address indexed account);
  event MinterRemoved(address indexed account);

  Roles.Role private minters;

  constructor() {
    minters.add(msg.sender);
  }

  modifier onlyMinter() {
    require(isMinter(msg.sender));
    _;
  }

  function isMinter(address account) public view returns (bool) {
    return minters.has(account);
  }

  function addMinter(address account) public onlyMinter {
    minters.add(account);
    emit MinterAdded(account);
  }

  function renounceMinter() public {
    minters.remove(msg.sender);
  }

  function _removeMinter(address account) internal {
    minters.remove(account);
    emit MinterRemoved(account);
  }
}

// File: library/ERC20.sol


pragma solidity ^0.8.4;

interface ERC20 {
    function totalSupply() external view returns (uint256);
    
    function balanceOf(address _owner) external view returns (uint256 balance);

    function transfer(address _to, uint256 _value)  external returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

    function approve(address _spender  , uint256 _value) external returns (bool success);

    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

// File: library/SafeMath.sol


pragma solidity ^0.8.4;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256){
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
 
    function div(uint256 a, uint256 b) internal pure returns (uint256){
        assert(b > 0);
        uint256 c = a / b;
        //??????????????????
        assert(a == b * c + a % b); 
        return c;
    }
 
    function sub(uint256 a, uint256 b) internal pure returns (uint256){
        assert(b <= a);
        assert(b >= 0);
        return a - b;
    }
 
    function add(uint256 a, uint256 b) internal pure returns (uint256){
        uint256 c = a + b;
        assert(c >= a && c >= b);
        return c;
    }
}

// File: contracts/TokenYHG.sol


pragma solidity ^0.8.4;



/// @title YHG ???????????????????????????
/// @author Aubrey
/// @notice Explain to an end user what this does
/// @dev Explain to a developer any extra details
contract TokenPET is ERC20 {

  // ??????
  string private _name = 'youhuigou';
  string private _symbol = 'YHG';
  // 8???????????????????????????100000000????????????????????????
  uint8 private _decimals = 8;
  uint256 private _totalSupply;
  uint256 constant private MAX_UINT256 = 2**256 - 1;
  uint256 private maxMintBlock = 0;

  // ?????? SafeMath ?????????
  using SafeMath for uint256;
  // ??????????????????
  mapping (address => mapping (address => uint256)) private allowed;
  // ??????????????????
  mapping (address => uint256) private balances;

  // ???????????????
  function name() public view returns (string memory) {
    return _name;
  }
  // ???????????????
  function symbol() public view returns (string memory) {
    return _symbol;
  }
  // ??????????????????????????? - ??????8??????????????????????????????100000000???????????????????????? 
  function decimals() public view returns (uint8) {
    return _decimals;
  }
  // ????????????????????????
  function totalSupply() public override view returns (uint256) {
    return _totalSupply;
  }
  // ??????????????????
  function balanceOf(address _owner) public override view returns (uint256 balance) {
    return balances[_owner];
  }
  // ???????????????
  function transfer(address _to, uint256 _value) public override returns (bool success) {
    assert(0 < _value);
    require(balances[msg.sender] >= _value);
    require(_to != address(0));
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }
  // ???????????????????????? 
  function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success) {
    uint256 _allowance = allowed[_from][msg.sender];
    assert (balances[_from] >= _value);
    assert (_allowance >= _value);
    assert (_value > 0);
    require(_to != address(0));
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }
  // ?????? _spender ???????????????????????????????????? _value ????????? ??????????????????????????????????????? _value ????????????????????? allowance ??????
  function approve(address _spender, uint256 _value) public override returns (bool success) {
    require(_spender != address(0));
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }
  //  ?????? _spender ?????????????????? _owner ??????????????????
  function allowance(address _owner, address _spender) public override view returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  // ???????????? ????????? _to ??????????????? _amount ????????? tokens????????? onlyOwner ???????????????????????????????????????????????? ????????????????????????????????????????????????????????????0?????????????????????
  function _mint(address _to, uint256 _amount) internal {
      require(_to != address(0));
      _totalSupply = _totalSupply.add(_amount);
      balances[_to] = balances[_to].add(_amount);
      emit Transfer(address(0), _to, _amount);
  }
  // ???????????? ???????????????????????????
  function _burn(address account, uint256 amount) internal {
    require(account != address(0));
    require(amount <= balances[account]);

    _totalSupply = _totalSupply.sub(amount);
    balances[account] = balances[account].sub(amount);
    emit Transfer(account, address(0), amount);
  }
  // ???????????? ???????????????????????????????????????
  function _burnFrom(address account, uint256 amount) internal {
    require(amount <= allowed[account][msg.sender]);

    // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
    // this function needs to emit an event with the updated approval.
    allowed[account][msg.sender] = allowed[account][msg.sender].sub(amount);
    _burn(account, amount);
  }

}

// File: contracts/TokenYHGMintable.sol


pragma solidity ^0.8.4;



contract TokenPETMintable is TokenPET, Ownable {
event MintingFinished();

  bool private _mintingFinished = false;

  modifier onlyBeforeMintingFinished() {
    require(!_mintingFinished);
    _;
  }

  /**
   * @return true if the minting is finished.
   */
  function mintingFinished() public view returns(bool) {
    return _mintingFinished;
  }

  /**
   * @dev Function to mint tokens
   * @param to The address that will receive the minted tokens.
   * @param amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(
    address to,
    uint256 amount
  )
    public
    onlyMinter
    onlyBeforeMintingFinished
    returns (bool)
  {
    _mint(to, amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting()
    public
    onlyMinter
    onlyBeforeMintingFinished
    returns (bool)
  {
    _mintingFinished = true;
    emit MintingFinished();
    return true;
  }

}