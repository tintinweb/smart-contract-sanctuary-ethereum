/**
 *Submitted for verification at Etherscan.io on 2022-03-30
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/**
 * See https://github.com/OpenZeppelin/openzeppelin-contracts/tree/master/contracts/token/ERC20
 */
interface IERC20 {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);

  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

/**
 * @dev Super-interface for wrapped ETH
 */
abstract contract IDummyToken is IERC20 {
  /**
   * @dev Deposit ETH and mint tokens.
   *
   * Amount of tokens minted will equal `msg.value`. The tokens will be added to the caller's balance.
   */
  function deposit() external virtual payable;
  /**
   * @dev Burn token and withdraw ETH.
   *
   * The withdrawn ETH will be sent to the caller.
   *
   * @param value Amount of tokens to burn.
   */
  function withdraw(uint value) external virtual;

  /**
   * @dev Emitted when ETH is deposited and tokens are minted.
   * @param sender The account.
   * @param value The amount deposited/minted.
   */
  event Deposit(address indexed sender, uint value);
  /**
   * @dev Emitted when tokens are burnt and ETH is withdrawn.
   * @param receiver The account.
   * @param value The amount withdrawn/burnt.
   */
  event Withdrawal(address indexed receiver, uint value);
}
/**
 * @dev Base class for all of our platform tokens.
 */
abstract contract PlatformToken {
  bool public isPlatformToken = true;

  /**
   * @dev Get whether this is a Nayms platform token.
   */
  function isNaymsPlatformToken () public view returns (bool) {
    return isPlatformToken;
  }
}

contract DummyToken is IDummyToken, PlatformToken {

  mapping (address => uint256) private balances;
  mapping (address => mapping (address => uint256)) private allowances;
  string public override name;
  string public override symbol;
  uint8 public override decimals;
  uint256 public override totalSupply;

  constructor (string memory _name, string memory _symbol, uint8 _decimals, uint256 _initialSupply, bool _isPlatformToken) {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
    totalSupply = _initialSupply;
    balances[msg.sender] = _initialSupply;
    isPlatformToken = _isPlatformToken;
  }

  function balanceOf(address account) public view override returns (uint256) {
      return balances[account];
  }

  function transfer(address recipient, uint256 amount) public override returns (bool) {
      _transfer(msg.sender, recipient, amount);
      return true;
  }

  function allowance(address owner, address spender) public view override returns (uint256) {
      return allowances[owner][spender];
  }

  function approve(address spender, uint256 amount) public override returns (bool) {
      _approve(msg.sender, spender, amount);
      return true;
  }

  function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
      unchecked {
        require(amount <= allowances[sender][msg.sender], "DummyToken: transfer amount exceeds allowance");          
        _approve(sender, msg.sender, allowances[sender][msg.sender] - amount);          
      }

      _transfer(sender, recipient, amount);
      return true;
  }

  function _transfer(address sender, address recipient, uint256 amount) internal {
      require(recipient != address(0), "DummyToken: transfer to the zero address");

      unchecked {
        require(amount <= balances[sender], "DummyToken: transfer amount exceeds balance");
        balances[sender] = balances[sender] - amount;
      }
      balances[recipient] = balances[recipient] + amount;
      emit Transfer(sender, recipient, amount);
  }

  function _approve(address owner, address spender, uint256 amount) internal {
      require(spender != address(0), "DummyToken: approve to the zero address");

      allowances[owner][spender] = amount;
      emit Approval(owner, spender, amount);
  }

  // IDummyToken

  function deposit() public payable override {
      balances[msg.sender] = balances[msg.sender] + msg.value;
      totalSupply = totalSupply + msg.value;
      emit Deposit(msg.sender, msg.value);
  }

  function withdraw(uint value) public override {
      // Balance covers value
      unchecked {
        require(value <= balances[msg.sender], 'DummyToken: insufficient balance');          
        balances[msg.sender] = balances[msg.sender] - value;
      }
      totalSupply = totalSupply - value;
      payable(msg.sender).transfer(value);
      emit Withdrawal(msg.sender, value);
  }
}