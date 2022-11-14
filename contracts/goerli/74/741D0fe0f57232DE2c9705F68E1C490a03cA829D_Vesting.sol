/**
 *Submitted for verification at Etherscan.io on 2022-11-14
*/

// File: VESTING_flat.sol


// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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

// File: contracts/VESTING.sol


pragma solidity ^0.8.4;


contract Vesting {
    IERC20 public token;
    address public receiver;
    uint[11] public arr;
    uint256 public amount;
    uint256 public expiry;
    uint public n;
    
    bool public locked = false;
    bool public claimed = false;

    constructor (address _token, uint256 _expiry) {
        token = IERC20(_token);
        expiry = _expiry;
       
    }

    function lock(address _from, address _receiver, uint256 _amount) external {
        require(!locked, "We have already locked tokens.");
        token.transferFrom(_from, address(this), _amount);
        receiver = _receiver;
        amount = _amount;
        
        locked = true;
    }

    function withdraw() external {
        require(locked, "Funds have not been locked");
        require(!claimed, "Tokens have already been claimed");
        

        while(n<arr.length)
        {
         arr[n] = expiry + 300*(n);
         require(block.timestamp > arr[n], "Tokens have not been unlocked");
         token.transfer(receiver, amount/12);
         n++;
        }
        
        claimed = true;
      
    }

    function getTime() external view returns (uint256) {
        return block.timestamp;
    }
}