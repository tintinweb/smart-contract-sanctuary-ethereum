// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "IERC20.sol";

contract DefiBank {

    uint256 startTime;
    uint256 endTime;

    address public Admin = 0x9515243Dfc19Df23B2877a411FAa6dB265bF8846;
    address public USDC = 0x5FdcF38f359c7408105dfA447590126591ba574f;
    address public soren = 0x4Fd2700fC5E38F60c0aa009cb1dbB3e311ed3E30;

    mapping(address => bool) deposeted;
    mapping(address => uint256) balances;

    event Stake(address staker, address token, uint256);
    event WithDraw(address staker, address token, uint256);
    event WithdrawInterest(address staker, address token, uint256);

    constructor(){

        startTime = block.timestamp;
        endTime = startTime + 7 days;
    
    }

    function stake(uint256 amount) public payable{

        require(block.timestamp >= startTime, 'too early');
        require(deposeted[msg.sender] == false, 'You can not invest twice');

        bool success = IERC20(USDC).transferFrom(msg.sender, address(this), amount);
        require(success == true, "transfer failed!");

        deposeted[msg.sender] = true;
        balances[msg.sender] += amount;

        emit Stake(msg.sender, USDC, amount);
        
    }

    function unstake() public payable{

        require(block.timestamp >= endTime, 'too early');
        require(balances[msg.sender] > 0, 'insufficient balance, You had unstaked your balance before');

        uint256 balance = balances[msg.sender];
        balances[msg.sender] = 0;

        IERC20(soren).transfer(msg.sender, balance / 100);
        IERC20(USDC).transfer(msg.sender, balance);

        emit WithDraw(msg.sender, USDC, balance);
        emit WithdrawInterest(msg.sender, soren, balance / 100);
    }

    function depositSoren(uint amount) public payable{

        require(msg.sender == Admin, "You can not have any access");
        IERC20(soren).transferFrom(msg.sender, address(this), amount);
    }

    function getbalance(address staker) public view returns(uint256){

        return balances[staker];
    }
}

// SPDX-License-Identifier: MIT

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