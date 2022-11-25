// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

// import "../libraries/math/SafeMath.sol";
import "../libraries/token/IERC20.sol";

contract BaseToken is IERC20 {
  //   using SafeMath for uint256;

  string public name;
  string public symbol;
  uint8 public constant decimals = 18;

  uint256 public override totalSupply;
  address public gov;

  bool public maintenancestate = true;
  uint256 public migrationTime;

  mapping(address => uint256) public balances;
  mapping(address => mapping(address => uint256)) public allowances;

  mapping(address => bool) public admins;

  // only checked when maintenancestate is true
  // this can be used to block the AMM pair as a recipient
  // and protect liquidity providers during a migration
  // by disabling the selling of BaseToken
  mapping(address => bool) public blockedRecipients;

  // only checked when maintenancestate is true
  // this can be used for:
  // - only allowing tokens to be transferred by the distribution contract
  // during the initial distribution phase, this would prevent token buyers
  // from adding liquidity before the initial liquidity is seeded
  // - only allowing removal of BaseToken liquidity and no other actions
  // during the migration phase
  mapping(address => bool) public allowedMsgSenders;

  modifier onlyGov() {
    require(msg.sender == gov, "BaseToken: forbidden");
    _;
  }

  modifier onlyAdmin() {
    require(admins[msg.sender], "BaseToken: forbidden");
    _;
  }

  constructor(string memory _name, string memory _symbol)
  // uint256 _initialSupply
  {
    name = _name;
    symbol = _symbol;
    gov = msg.sender;
    admins[msg.sender] = true;
    // _mint(msg.sender, _initialSupply);
  }

  function toggleMaintenance() external onlyAdmin {
    maintenancestate = !maintenancestate;
  }

  function clearMaintenance() external onlyAdmin {
    maintenancestate = false;
  }

  function setMaintenance() external onlyAdmin {
    maintenancestate = true;
  }

  function getMaintenance() external view returns (bool) {
    return maintenancestate;
  }

  function addBlockedRecipient(address _recipient) external onlyGov {
    blockedRecipients[_recipient] = true;
  }

  function removeBlockedRecipient(address _recipient) external onlyGov {
    blockedRecipients[_recipient] = false;
  }

  function addMsgSender(address _msgSender) external onlyGov {
    allowedMsgSenders[_msgSender] = true;
  }

  function removeMsgSender(address _msgSender) external onlyGov {
    allowedMsgSenders[_msgSender] = false;
  }

  // to help users who accidentally send their tokens to this contract
  function withdrawToken(
    address _token,
    address _account,
    uint256 _amount
  ) external onlyGov {
    IERC20(_token).transfer(_account, _amount);
  }

  function balanceOf(address _account)
    external
    view
    override
    returns (uint256)
  {
    return balances[_account];
  }

  function transfer(address _recipient, uint256 _amount)
    external
    override
    returns (bool)
  {
    _transfer(msg.sender, _recipient, _amount);
    return true;
  }

  function allowance(address _owner, address _spender)
    external
    view
    override
    returns (uint256)
  {
    return allowances[_owner][_spender];
  }

  function approve(address _spender, uint256 _amount)
    external
    override
    returns (bool)
  {
    _approve(msg.sender, _spender, _amount);
    return true;
  }

  function transferFrom(
    address _sender,
    address _recipient,
    uint256 _amount
  ) external override returns (bool) {
    uint256 currentAllowance = allowances[_sender][msg.sender];
    require(
      currentAllowance >= _amount,
      "BaseToken: transfer amount exceeds allowance"
    );
    uint256 nextAllowance = currentAllowance - _amount;
    _approve(_sender, msg.sender, nextAllowance);
    _transfer(_sender, _recipient, _amount);
    return true;
  }

  function _transfer(
    address _sender,
    address _recipient,
    uint256 _amount
  ) private {
    require(_sender != address(0), "BaseToken: transfer from the zero address");
    require(
      _recipient != address(0),
      "BaseToken: transfer to the zero address"
    );

    if (maintenancestate) {
      require(
        allowedMsgSenders[msg.sender],
        "BaseToken maintenance: forbidden msg.sender"
      );
      require(
        !blockedRecipients[_recipient],
        "BaseToken maintenance: forbidden recipient"
      );
    }

    require(
      balances[_sender] >= _amount,
      "BaseToken: transfer amount exceeds balance"
    );
    balances[_sender] = balances[_sender] - _amount;
    balances[_recipient] = balances[_recipient] + _amount;

    emit Transfer(_sender, _recipient, _amount);
  }

  function _mint(address _account, uint256 _amount) internal {
    require(_account != address(0), "BaseToken: mint to the zero address");

    totalSupply = totalSupply + _amount;
    balances[_account] = balances[_account] + _amount;

    emit Transfer(address(0), _account, _amount);
  }

  function _approve(
    address _owner,
    address _spender,
    uint256 _amount
  ) private {
    require(_owner != address(0), "BaseToken: approve from the zero address");
    require(_spender != address(0), "BaseToken: approve to the zero address");

    allowances[_owner][_spender] = _amount;

    emit Approval(_owner, _spender, _amount);
  }

  function _burn(address _owner, uint256 _amount) internal {
    require(_owner != address(0), "ERC20: burn from the zero address");

    uint256 accountBalance = balances[_owner];
    require(accountBalance >= _amount, "ERC20: burn amount exceeds balance");
    unchecked {
      balances[_owner] = accountBalance - _amount;
      // Overflow not possible: amount <= accountBalance <= totalSupply.
      totalSupply -= _amount;
    }

    emit Transfer(_owner, address(0), _amount);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./MintableBaseToken.sol";

contract HLP is MintableBaseToken {
  constructor() MintableBaseToken("House of Matrix Liquidity token", "HLP") {}

  function id() external pure returns (string memory _name) {
    return "HLP";
  }

  function setMinter(address _minter, bool _isActive)
    external
    override
    onlyGov
  {
    isMinter[_minter] = _isActive;
  }

  function mint(address _account, uint256 _amount)
    external
    override
    onlyMinter
  {
    _mint(_account, _amount);
  }

  function burn(address _account, uint256 _amount)
    external
    override
    onlyMinter
  {
    _burn(_account, _amount);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IMintable {
    function isMinter(address _account) external returns (bool);

    function setMinter(address _minter, bool _isActive) external;

    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./BaseToken.sol";
import "./IMintable.sol";

contract MintableBaseToken is BaseToken, IMintable {
  mapping(address => bool) public isMinter;

  constructor(string memory _name, string memory _symbol)
    BaseToken(_name, _symbol)
  {}

  modifier onlyMinter() {
    require(isMinter[msg.sender], "MintableBaseToken: forbidden");
    _;
  }

  function setMinter(address _minter, bool _isActive) external virtual onlyGov {
    isMinter[_minter] = _isActive;
  }

  function mint(address _account, uint256 _amount) external virtual onlyMinter {
    _mint(_account, _amount);
  }

  function burn(address _account, uint256 _amount) external virtual onlyMinter {
    _burn(_account, _amount);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256);

  /**
   * @dev Moves `amount` tokens from the caller's account to `recipient`.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transfer(address recipient, uint256 amount) external returns (bool);

  /**
   * @dev Returns the remaining number of tokens that `spender` will be
   * allowed to spend on behalf of `owner` through {transferFrom}. This is
   * zero by default.
   *
   * This value changes when {approve} or {transferFrom} are called.
   */
  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  /**
   * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * IMPORTANT: Beware that changing an allowance with this method brings the risk
   * that someone may use both the old and the new allowance by unfortunate
   * transaction ordering. One possible solution to mitigate this race
   * condition is to first reduce the spender's allowance to 0 and set the
   * desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   *
   * Emits an {Approval} event.
   */
  function approve(address spender, uint256 amount) external returns (bool);

  /**
   * @dev Moves `amount` tokens from `sender` to `recipient` using the
   * allowance mechanism. `amount` is then deducted from the caller's
   * allowance.
   *
   * Returns a boolean value indicating whether the operation succeeded.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  /**
   * @dev Emitted when `value` tokens are moved from one account (`from`) to
   * another (`to`).
   *
   * Note that `value` may be zero.
   */
  event Transfer(address indexed from, address indexed to, uint256 value);

  /**
   * @dev Emitted when the allowance of a `spender` for an `owner` is set by
   * a call to {approve}. `value` is the new allowance.
   */
  event Approval(address indexed owner, address indexed spender, uint256 value);
}