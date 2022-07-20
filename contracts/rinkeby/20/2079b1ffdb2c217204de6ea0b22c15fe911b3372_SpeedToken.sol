/**
 *Submitted for verification at Etherscan.io on 2022-07-20
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

pragma solidity ^0.8.0;

contract SpeedToken is IERC20{
    string public name="Speed token coin"; // 代币的名称
    uint8 public decimals = 18;// 精确小数点位数
    string public symbol = "SPD";//代币符号
    uint public totalPublic;//代币发行量
    
    mapping (address => uint256) public balances;// 余额map 
    mapping (address => mapping(address =>uint256)) public allowed;// 授权map

    constructor() {
        totalPublic = 1e30;
        balances[msg.sender] = totalPublic;
    }

    function totalSupply() external override view returns (uint256 _totalPublic) {
        return totalPublic;
    }
    
    // 根据地址获取获取代币金额 
    function balanceOf(address _owner) public override view returns (uint256 balance) {
        return balances[_owner];
    }
    
    // 授权额度申请 
    function approve(address _spender, uint256 _value) public override returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
    // 根据 _owner和 _spender查询 _owner给 _spender授权了多少额度 
    function allowance(address _owner, address _spender) public override view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    // 转账 
    function transfer(address _to, uint256 _value) public override returns (bool success) {
        require(balances[msg.sender] >= _value);
        require(balances[_to] + _value >= balances[_to]);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success) {
        uint256 allowanceValue = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowanceValue >= _value);
        require(balances[_to] + _value > balances[_to]);
        allowed[_from][msg.sender] -= _value;
        balances[_to] += _value;
        balances[_from] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
}