// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;
import "../../interface/IERC20.sol";

contract Dyst is IERC20 {
	string public symbol = "OMNI";
	string public name = "Omnitopia token";
	uint8 public decimals = 18;
	uint public totalSupply = 0;
	mapping(address => uint) public balanceOf;
	mapping(address => mapping(address => uint)) public allowance;
	address public minter;

	constructor() {
		minter = msg.sender;
		_mint(msg.sender, 0);
	}

	function setMinter(address _minter) external {
		require(msg.sender == minter, "OMNI: Not minter");
		minter = _minter;
	}

	function approve(address _spender, uint _value) external override returns(bool) {
		require(_spender != address(0), "OMNI: Approve to the zero address");
		allowance[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}

	function _mint(address _to, uint _amount) internal returns(bool) {
		require(_to != address(0), "OMNI: Mint to the zero address");
		balanceOf[_to] += _amount;
		totalSupply += _amount;
		emit Transfer(address(0x0), _to, _amount);
		return true;
	}

	function _transfer(address _from, address _to, uint _value) internal returns(bool) {
		require(_to != address(0), "OMNI: Transfer to the zero address");
		uint fromBalance = balanceOf[_from];
		require(fromBalance >= _value, "OMNI: Transfer amount exceeds balance");

		balanceOf[_to] += _value;
		emit Transfer(_from, _to, _value);
		return true;
	}

	function transfer(address _to, uint _value) external override returns(bool) {
		return _transfer(msg.sender, _to, _value);
	}

	function transferFrom(address _from, address _to, uint _value) external override returns(bool) {
		address spender = msg.sender;
		uint spenderAllowance = allowance[_from][spender];
		if (spenderAllowance != type(uint).max) {
			require(spenderAllowance >= _value, "OMNI: Insufficient allowance");

		}
		return _transfer(_from, _to, _value);
	}

	function mint(address account, uint amount) external returns(bool) {
		require(msg.sender == minter, "OMNI: Not minter");
		_mint(account, amount);
		return true;
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

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
  function allowance(address owner, address spender) external view returns (uint256);

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