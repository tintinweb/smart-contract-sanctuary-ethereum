// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
contract SafeStorage{

    event Deposit(uint256 amount);
    event WithDrawal(uint256 amount);

    using SafeMath for uint256;
    mapping(address => uint256) public storageBalance;

    function getBalance(address _token, address _owner) public view returns (uint256) {
        return IERC20(_token).balanceOf(_owner);
    }
    
    function deposit(address token, uint256 _amount) public returns (uint256){
        
        IERC20(token).approve(address(this), IERC20(token).balanceOf(msg.sender));
        IERC20(token).transferFrom(msg.sender, address(this), _amount);
        if(storageBalance[msg.sender] == 0){
            storageBalance[msg.sender] = _amount;
        }
        else{
            // storageBalance[msg.sender] = storageBalance[msg.sender].add(_amount);
            storageBalance[msg.sender] += _amount;
        }
        emit Deposit(_amount);
        return storageBalance[msg.sender];
    }

    function getMyStorageBalance() public view returns (uint256){
        return storageBalance[msg.sender];
    }

    function withDrawal(address token, uint256 _amount) public returns (uint256){
        IERC20(token).transfer(msg.sender,_amount);
        // storageBalance[msg.sender] = storageBalance[msg.sender].sub(_amount);
        storageBalance[msg.sender] -= _amount;
        emit WithDrawal(_amount);
        return storageBalance[msg.sender];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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